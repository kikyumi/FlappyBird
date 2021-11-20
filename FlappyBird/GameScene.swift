//
//  GameScene.swift
//  FlappyBird
//
//  Created by 菊川 由美 on 2021/11/14.
//
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird: SKSpriteNode!
    var itemNode: SKNode!
    
    //アイテム取得音の音源ファイルを指定
    let playItemSound = Bundle.main.bundleURL.appendingPathComponent("getItem.mp3")
    //AVAudioPlayerのインスタンス宣言
    var soundPlayer: AVAudioPlayer!
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4       // 0...10000
    
    // スコア用
    var score = 0
    var itemScore = 0
    let userDefaults: UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    
    
    // SKView上にscene（＝GameSceneのインスタンス）が表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)

        
        // 各種スプライトを生成
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupItem()
    }
    
    
    func setupGround(){
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNubmer = Int(frame.size.width / groundTexture.size().width + 2)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        // テクスチャを指定してスプライトを作成する
        for i in 0..<needNubmer {
            let groundSprite = SKSpriteNode(texture: groundTexture)
            // スプライトの表示する位置を指定する
            groundSprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2)
            
            // スプライトに物理演算を設定する
            groundSprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            // 衝突の時に動かないように設定する
            groundSprite.physicsBody?.isDynamic = false
            // 衝突のカテゴリー設定
            groundSprite.physicsBody?.categoryBitMask = groundCategory
            
            // スプライトにアクションを設定する
            groundSprite.run(repeatScrollGround)
            // scrollNodeにスプライトを追加する
            scrollNode.addChild(groundSprite)
        }
    }
    
    func setupCloud(){
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNubmer = Int(frame.size.width / cloudTexture.size().width + 2)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // cloudのスプライトを配置する
        // テクスチャを指定してスプライトを作成する
        for i in 0..<needNubmer {
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.zPosition = -100
            
            // スプライトの表示する位置を指定する
            cloudSprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: size.height - cloudTexture.size().height / 2
            )
            // スプライトにアクションを設定する
            cloudSprite.run(repeatScrollCloud)
            // scrollNodeにスプライトを追加する
            scrollNode.addChild(cloudSprite)
        }
        
    }

    
    //壁セットアップ
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = frame.size.width + wallTexture.size().width
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (frame.size.height - groundSize.height) / 2
        // 空の中央位置を基準にして下の壁の中央位置を取得
        let underWall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run ({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // -random_y_range〜random_y_rangeの範囲のランダム値を生成
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            // 下の壁の中央位置にランダム値を足して、下の壁の表示位置を決定
            let under_wall_y = underWall_center_y + random_y
            // 下壁スプライトを作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            // 下壁スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            //underを配置
            wall.addChild(under)
            
            // 上壁スプライトを作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            // 上壁スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            //upperを配置
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.size.height)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    //■■■■■■アイテムのセットアップ■■■■■■■
    func setupItem(){
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "lemon")
        itemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = frame.size.width + itemTexture.size().width
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
                
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run ({
            //スプライトを作成して設置
            let item = SKSpriteNode(texture: itemTexture)
            // アイテムの上下の振れ幅を設定
            let item_random_y_range: CGFloat = 40
            // -random_y_range〜random_y_rangeの範囲のランダム値を生成
            let item_random_y = CGFloat.random(in: -item_random_y_range...item_random_y_range)
            //アイテムのポジションを設定（yは空の中央位置±振れ幅）
            let groundSize = SKTexture(imageNamed: "ground").size()
            let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
            item.position = CGPoint(
                x: self.frame.size.width / 4 * 3.3,
                y: sky_center_y + item_random_y)
            item.zPosition = -50 // 壁と同じ
            //itemスプライトのサイズを設定
            let birdSize = SKTexture(imageNamed: "bird_a").size()
            item.size = CGSize(width: birdSize.width * 1.1, height: birdSize.height * 1.1)
            
            // 物理演算を設定
            item.physicsBody = SKPhysicsBody(circleOfRadius: item.size.height / 2)
            item.physicsBody?.categoryBitMask = self.itemCategory
            // 衝突の時に動かないように設定する
            item.physicsBody?.isDynamic = false
            //birdとぶつかったときに判定できるようにする
            item.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.run(itemAnimation)
            self.itemNode.addChild(item)
        })
        
        // 次のアイテム作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        // アイテムを作成->時間待ち->……を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        itemNode.run(repeatForeverAnimation)
    }
    
    
    func setupBird() {
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = wallCategory | groundCategory
        bird.physicsBody?.contactTestBitMask = wallCategory | groundCategory
        
        // アニメーションを設定
        bird.run(flap)
        // スプライトを追加する
        addChild(bird)
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.fontSize = 20
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score: \(score)"
        addChild(scoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.fontSize = 20
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 50)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score: \(itemScore)"
        addChild(itemScoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.fontSize = 20
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 80)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score: \(bestScore)"
        addChild(bestScoreLabelNode)
    }
    
    //リスタートするメソッドを作成
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        wallNode.removeAllChildren()
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0{
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if scrollNode.speed == 0{
            restart()
        }
    }
    
    
    // ■■■■■SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる■■■■■
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            let totalScore = score + itemScore
            if totalScore > bestScore {
                bestScore = totalScore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
                }
            
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory{
            // アイテムと衝突（アイテムを獲得）した
            print("ItemScoreUp")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            //■■■■■音を鳴らす■■■■■■
            //サウンドプレイヤーに、音源ファイル名を指定
            soundPlayer = try! AVAudioPlayer(contentsOf: playItemSound, fileTypeHint: nil)
            soundPlayer!.play()

            //■■■■■獲得したアイテムを消す■■■■■
            contact.bodyB.node?.removeFromParent()
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            let totalScore = score + itemScore
            if totalScore > bestScore {
                bestScore = totalScore
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
                }
        }else{
                // 壁か地面と衝突した
                print("GameOver")
                // スクロールを停止させる
                scrollNode.speed = 0
                bird.physicsBody?.collisionBitMask = groundCategory
                let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
                bird.run(roll, completion:{
                    self.bird.speed = 0
                })
            }
    }

}

