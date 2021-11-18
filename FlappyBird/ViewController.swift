//
//  ViewController.swift
//  FlappyBird
//
//  Created by 菊川 由美 on 2021/11/14.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 今のビューを、SKView型に変換する
        let skView = view as! SKView
        
        // FPSを表示する
        skView.showsFPS = true
        
        // ノードの数を表示する
        skView.showsNodeCount = true
        
        // SKSceneクラスを継承した、GameSceneのインスタンスを作る（SKViewのインスタンスと同じサイズで）
        let scene = GameScene(size: skView.frame.size)
        
        // SKViewのインスタンスに、SKSceneのインスタンスを表示する
        skView.presentScene(scene)
    }
    
    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }


}

