//
//  GraphTests.swift
//
//
//  Created by Valentin Radu on 11/01/2022.
//

@testable import Helm
import XCTest

private typealias TestGraphEdge = DirectedEdge<TestNode>
private typealias TestGraph = Set<TestGraphEdge>

class GraphTests: XCTestCase {
    func testPrintEdge() {
        XCTAssertEqual(TestGraphEdge.ab.debugDescription, "a -> b")
    }
    
    func testHasEdge() {
        let graph = TestGraph([.ab])
        
        XCTAssertTrue(graph.has(edge: .ab))
        XCTAssertFalse(graph.has(edge: .bc))
    }
    
    func testHasNode() {
        let graph = TestGraph([.ab])
        
        XCTAssertTrue(graph.has(node: .a))
        XCTAssertTrue(graph.has(node: .b))
        XCTAssertFalse(graph.has(node: .c))
    }
    
    func testHasCycle() {
        let cyclicGraph = TestGraph([.ab, .bc, .cd, .db])
        XCTAssertTrue(cyclicGraph.hasCycle)
        
        let acyclicGraph = TestGraph([.ab, .bc, .cd, .ad])
        XCTAssertFalse(acyclicGraph.hasCycle)
        
        let emptyGraph = TestGraph([])
        XCTAssertFalse(emptyGraph.hasCycle)
    }
    
    func testEgressEdges() {
        let graph = TestGraph([.ab, .bc, .bd, .ba])
        XCTAssertEqual(graph.egressEdges(for: .b), [.bc, .bd, .ba])
        XCTAssertEqual(graph.egressEdges(for: [.a, .b, .c]), [.ab, .bc, .bd, .ba])
        XCTAssertEqual(try! graph.uniqueEgressEdge(for: .a), .ab)
        
        let ambiguousError = HelmError<TestGraphEdge>.ambiguousEgressEdges([.bc, .bd, .ba],
                                                                           from: .b)
        XCTAssertThrowsError(try graph.uniqueEgressEdge(for: .b),
                             ambiguousError.localizedDescription)
        
        let missingError = HelmError<TestGraphEdge>.missingEgressEdges(from: .d)
        XCTAssertThrowsError(try graph.uniqueEgressEdge(for: .d),
                             missingError.localizedDescription)
    }
    
    func testIngressEdges() {
        let graph = TestGraph([.ab, .cb, .db, .ba])
        XCTAssertEqual(graph.ingressEdges(for: .b), [.ab, .cb, .db])
        XCTAssertEqual(graph.ingressEdges(for: [.a, .b, .c]), [.ab, .cb, .db, .ba])
        
        let ambiguousError = HelmError<TestGraphEdge>.ambiguousIngressEdges([.ab, .cb, .db],
                                                                            to: .b)
        XCTAssertThrowsError(try graph.uniqueIngressEdge(for: .b),
                             ambiguousError.localizedDescription)
        
        let missingError = HelmError<TestGraphEdge>.missingIngressEdges(to: .d)
        XCTAssertThrowsError(try graph.uniqueIngressEdge(for: .d),
                             missingError.localizedDescription)
    }
    
    func testInlets() {
        let cyclicGraph = TestGraph([.ab, .bc, .cb, .ba])
        XCTAssertEqual(cyclicGraph.inlets, [])
        
        let emptyGraph = TestGraph([])
        XCTAssertEqual(emptyGraph.inlets, [])
        
        let graph = TestGraph([.ab, .bc, .cb, .db])
        XCTAssertEqual(graph.inlets, [.ab, .db])
    }
    
    func testOutlets() {
        let cyclicGraph = TestGraph([.ab, .bc, .cb, .ba])
        XCTAssertEqual(cyclicGraph.outlets, [])
        
        let emptyGraph = TestGraph([])
        XCTAssertEqual(emptyGraph.outlets, [])
        
        let graph = TestGraph([.ab, .bc, .cb, .bd])
        XCTAssertEqual(graph.outlets, [.bd])
    }
    
    func testNodes() {
        let graph = TestGraph([.ab, .bc, .cb])
        XCTAssertEqual(graph.nodes, [.a, .b, .c])
    }
    
    func testDisconnectedSubgraphs() {
        let emptyGraph = TestGraph([])
        XCTAssertEqual(emptyGraph.disconnectedSubgraphs, [])
        
        let singleGraph = TestGraph([.ab, .bc, .ac])
        XCTAssertEqual(singleGraph.disconnectedSubgraphs, [[.ab, .bc, .ac]])
        
        let multiGraph = TestGraph([.ab, .bc, .ac, .de, .df])
        XCTAssertEqual(multiGraph.disconnectedSubgraphs,
                       [[.ab, .bc, .ac], [.de, .df]])
    }
    
    func testDFS() {
        let graph = TestGraph([.ab, .ac, .cd, .ch, .df, .hf, .de, .dg, .hj, .jg])
        
        XCTAssertEqual(graph.dfs(),
                       [.ab, .ac, .cd, .de, .dg, .df, .ch, .hj, .hf, .jg])
    }
}
