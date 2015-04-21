/*
P2PBrain.swift
SwiftMultipeerConnectivityTemplate

Created by Jonathan Neumann on 21/04/2015.
Copyright (c) 2015 Audio Y. All rights reserved.
www.audioy.co

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
In the background, MCNearbyServiceBrowser and MCNearbyServiceAdvertiser stop working (even with a background mode on)
So we need to check that the peers found are not already in the array
Otherwise everytime we go foreground -> background -> foreground the same found peer is added to the array
*/

import Foundation
import MultipeerConnectivity

class P2PBrain: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    let serviceType = "SwiftP2P"
    
    var peer:MCPeerID!
    var session:MCSession!
    var browser:MCNearbyServiceBrowser!
    var advertiser:MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var connectedPeers = [MCPeerID]()
    //var invitationHandler: ((Bool, MCSession!)->Void)!
    
    override init() {
        super.init()
        
        peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
        
        println("P2P Brain initialised")
    }
    
    
    // Make P2P Brain a Singleton
    // iOS 8.3 / Swift 1.2 onwards only
    // static let sharedInstance = P2PBrain()
    // iOS < 8.3
    class var sharedInstance :P2PBrain {
        struct Singleton {
            static let instance = P2PBrain()
        }
        
        return Singleton.instance
    }
    
    
    //MARK: SESSION DELEGATE
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        switch state{
        case MCSessionState.NotConnected:
            println("Not connected to \(peerID.displayName)")
            removePeerFromConnectedArray(peerID)
        case MCSessionState.Connecting:
            println("Connecting to \(peerID.displayName)")
        case MCSessionState.Connected:
            println("Connected to \(peerID.displayName)")
            connectedPeers.append(peerID)
        }
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        println("Did receive data from \(peerID.displayName)")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        println("Did start receiving \(resourceName) from \(peerID.displayName)")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        println("Did finish receiving \(resourceName) from \(peerID.displayName)")
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        println("Did receive stream \(streamName) from \(peerID.displayName)")
    }
    
    //MARK: BROWSER DELEGATE
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("Found \(peerID.displayName)")
        if let indexOfPeer = findIndexOfPeerInArray(peerID, arrayToSearch: foundPeers){
            println("\(peerID.displayName) is already in the array")
            return
        }
        
        foundPeers.append(peerID)
        println("\(peerID.displayName) was added to the array")
        
        // TESTING - automatically connect to one of my phones when found
        if peerID.displayName == "J5 iPhone"{
            
            if let indexOfPeer = findIndexOfPeerInArray(peerID, arrayToSearch: connectedPeers){
                println("\(peerID.displayName) is already connected")
                return
            }
            browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 20)
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("Lost \(peerID.displayName)")
        removePeerFromFoundArray(peerID)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println("Couldn't browse: \(error.localizedDescription)")
    }
    
    //MARK: ADVERTISER DELEGATE
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        println("Invitation received to connect to \(peerID.displayName)")
        //self.invitationHandler = invitationHandler
        
        if let indexOfPeer = findIndexOfPeerInArray(peerID, arrayToSearch: connectedPeers){
            println("\(peerID.displayName) is already connected")
            invitationHandler(false, session)
            return
        }
        
        // TESTING - automatically accept the connection
        invitationHandler(true, session)
        
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("Couldn't advertise: \(error.localizedDescription)")
    }
    
    // MARK: CUSTOM METHODS
    func removePeerFromFoundArray(peerToRemove:MCPeerID){
        
        if let indexOfPeer = findIndexOfPeerInArray(peerToRemove, arrayToSearch: foundPeers){
            foundPeers.removeAtIndex(indexOfPeer)
            println("\(peerToRemove.displayName) was removed from Found Peers")
        }
    }
    
    func removePeerFromConnectedArray(peerToRemove:MCPeerID){
        
        if let indexOfPeer = findIndexOfPeerInArray(peerToRemove, arrayToSearch: connectedPeers){
            connectedPeers.removeAtIndex(indexOfPeer)
            println("\(peerToRemove.displayName) was removed from Connected Peers")
        }
    }
    
    func findIndexOfPeerInArray(peerToSearch:MCPeerID, arrayToSearch:[MCPeerID]) -> Int?{
        
        for (index, peer) in enumerate(arrayToSearch){
            if peer == peerToSearch {
                return index
            }
        }
        return nil
    }
    
}
