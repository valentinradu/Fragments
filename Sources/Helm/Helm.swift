//
//  File.swift
//
//
//  Created by Valentin Radu on 10/12/2021.
//

import Collections
import Foundation
import SwiftUI

private extension DirectedGraph {
    func presentedSections<N: Section>(for _: GraphPath<DirectedEdge<N>>) -> GraphPath<DirectedEdge<N>> where N == Element.N {
        []
    }
}

/// `Helm` holds all navigation rules between sections in the app, plus the path that leads to the currently presented ones.
public class Helm<N: Section>: ObservableObject {
    /// The graph that describes all the navigation rules in the app.
    public let nav: DirectedGraph<Segue<N>>

    /// The currently presented sections and the relationship between them.
    public private(set) var path: GraphPath<DirectedEdge<N>> {
        didSet {
            presentedSections = nav.presentedSections(for: path)
        }
    }

    /// The presented sections in the order they were presented.
    @Published public private(set) var presentedSections: GraphPath<DirectedEdge<N>>

    /// All the errors triggered by navigating
    @Published public private(set) var errors: [Error]

    /// Initializes a new Helm instance.
    /// - parameter nav: A directed graph of segues that defies all the navigation rules between sections in the app.
    /// - parameter path: The path that leads to the currently presented sections.
    public init(nav: DirectedGraph<Segue<N>>,
                path: GraphPath<DirectedEdge<N>> = []) throws
    {
        errors = []
        presentedSections = nav.presentedSections(for: path)
        self.nav = nav
        self.path = path
        try validate()
    }

    /// Presents a section.
    /// A segue must connect it to one of the presented section.
    /// If there is no such segue, the operation fails.
    /// If multiple presented origin sections are available, the search starts with the lastest.
    /// - parameter section: The given section.
    public func present(section: N) {
        do {
            if path.isEmpty {
                let segue = try nav.inlets.uniqueIngressEdge(for: section)
                try trigger(edge: segue.edge, direction: .present)
            }
            else {
                let segues = nav
                    .egressEdges(for: OrderedSet(presentedSections.nodes.reversed()))
                    .ingressEdges(for: section)

                guard let segue = segues.first else {
                    throw GraphError.missingEgress(node: section)
                }

                try trigger(edge: segue.edge, direction: .present)
            }
        }
        catch {
            errors.append(error)
        }
    }

    /// Presents a section by triggering a segue with a specific tag.
    /// The segue must originate from a presented section.
    /// If there is no such segue, the operation fails.
    /// - parameter tag: The tag to look after.
    public func present<T: SegueTag>(tag: T) {
        do {
            guard let segue = nav.first(where: { $0.tag == AnyHashable(tag) }) else {
                throw HelmError.missingTag(name: tag)
            }

            try trigger(edge: segue.edge, direction: .present)
        }
        catch {
            errors.append(error)
        }
    }

    /// Presents the next section by triggering the sole egress segue of the latest presented section.
    /// If the section has more than a segue, the operation fails
    /// If the section has no segue, the operation fails
    public func forward() {
        do {
            if path.isEmpty {
                let segues = nav.inlets

                guard segues.count == 1 else {
                    throw HelmError.ambiguousForwardInlets
                }

                let segue = segues.first!
                try trigger(edge: segue.edge, direction: .present)
            }
            else {
                let section = path.last!.out
                let segue = try nav.uniqueEgressEdge(for: section)
                try trigger(edge: segue.edge, direction: .present)
            }
        }
        catch {
            errors.append(error)
        }
    }

    /// Dismisses a section.
    /// If the section is not already presented, the operation fails.
    /// If the section has no dismissable ingress segues, the operation fails.
    /// - note: Only the segues in the path (already visited) are considered.
    /// - parameter section: The given section.
    public func dismiss(section: N) {
        do {
            let segues = nav
                .ingressEdges(for: OrderedSet(presentedSections.nodes.reversed()))
                .filter { $0.dismissable }

            guard segues.count > 0 else {
                throw HelmError.noDismissableSegue(section: section)
            }

            let segue = segues.first!
            try trigger(edge: segue.edge, direction: .dismiss)
        }
        catch {
            errors.append(error)
        }
    }

    /// Dismisses a section by triggering in reverse a segue with a specific tag.
    /// If there is no such segue in the path (already visited), the operation fails.
    /// - parameter tag: The tag to look after.
    public func dismiss<T: SegueTag>(tag: T) {
        do {
            guard let segue = nav.first(where: { $0.tag == AnyHashable(tag) }) else {
                throw HelmError.missingTag(name: tag)
            }

            try trigger(edge: segue.edge, direction: .dismiss)
        }
        catch {
            errors.append(error)
        }
    }

    /// Dismisses the last presented section.
    /// The operation fails if the section has no dismissable ingress segue.
    public func dismiss() {
        do {
            guard let edge = path.last else {
                throw HelmError.cantDimissEmptyPath
            }
            
            try trigger(edge: edge, direction: .dismiss)
        }
        catch {
            errors.append(error)
        }
    }

    /// Triggers a segue by its edge and direction.
    /// If possible, use one of the present or dismiss methods instead.
    public func trigger(edge _: DirectedEdge<N>, direction _: SegueDirection) throws {
//        guard presentedSections.nodes.contains(section) else {
//            throw HelmError.dismissingUnpresented(section: section)
//        }
    }

    /// Checks if a section is presented. Shorthand for `presentedSections.has(node: section)`
    /// - returns: True if the section is presented.
    public func isPresented(_ section: N) -> Bool {
        return presentedSections.has(node: section)
    }

    /// A special `isPresented(section:)` function that returns a binding.
    /// Setting the value to false from the binding is the same thing as calling `dismiss(section:)` with the section as the parameter
    /// - parameter section: The section
    /// - returns: A binding, true if the section is presented.
    public func isPresented(_ section: N) -> Binding<Bool> {
        return Binding {
            self.isPresented(section)
        } set: {
            if $0 {
                self.present(section: section)
            }
            else {
                self.dismiss(section: section)
            }
        }
    }

    private func validate() throws {
        if nav.isEmpty {
            throw HelmError.emptyNav
        }

        if nav.inlets.count == 0 {
            throw HelmError.noNavInlets
        }

        if let segues = nav.filter({ $0.auto }).firstCycle {
            throw HelmError.autoCycleDetected(segues: segues)
        }
    }
}