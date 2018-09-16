//
//  ViewController.swift
//  tinderCards
//
//  Created by Paulo Jose on 08/09/18.
//  Copyright © 2018 Paulo Jose. All rights reserved.
//

import UIKit

enum CardPosition {
    case front
    case back
}

class ViewController: UIViewController {
    
    let colorsArr = [
        UIColor.red,
        UIColor.green,
        UIColor.blue,
        UIColor.brown,
        UIColor.black,
        UIColor.cyan,
        UIColor.darkGray
    ]
    
    var cardsViews = [UIView]()
    
    var tempView: UIView!
    
    var cardsOrigin: CGPoint = CGPoint.zero
    var cardSize: CGSize = CGSize.zero
    
    var likePoint = CGPoint.zero
    var dislikePoint = CGPoint.zero
    
    override func viewWillAppear(_ animated: Bool) {
        
        cardsOrigin = view.center
        
        //Points used as reference to animate card on gestures
        likePoint = CGPoint(x: view.frame.width + 500, y: view.center.y)
        dislikePoint = CGPoint(x: view.frame.origin.x - 500, y: view.center.y)
        
        let firstView = createCardFor(position: .front)
        let secondView = createCardFor(position: .back)
        
        cardsViews.append(contentsOf: [firstView, secondView])
        
        view.addSubview(cardsViews[1])
        view.addSubview(cardsViews[0])
        
        appendGestureRecognizer(to: cardsViews[0])
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: self.view)
        
        switch sender.state {
        case .changed:
            
            //Change front card position based on current translation
            cardsViews[0].center.x = cardsOrigin.x + translation.x
            cardsViews[0].center.y = cardsOrigin.y + translation.y
            
            //Change back card scale bases on translation. The bigger the translation, the bigger the back card scale
            //The maxi translation to use as reference is 100 points. Higger absolute values are ignored
            let currentTranslationX = (translation.x > 100) || (translation.x < -100) ? 100 : abs(translation.x)
            
            let scale = 0.9 + ((currentTranslationX / 100) * 0.1) //This line take the percentage of the max translation has been moved, converts it to 0.1 scale and sums with 0.9
            
            cardsViews[1].transform = CGAffineTransform(scaleX: scale, y: scale)
            
            //This function rotates front cards based on translation. The bigger the translation on the X axis, the bigger the rotation
            rotate(view: cardsViews[0], for: translation)
            
        case .ended:
            
            if translation.x > 100.0 { // When the user perfoms a PanGesture to the right, with a 100 points of distance from its origin, it perfoms a like
                UIView.animate(withDuration: 0.46, delay: 0, options: [.curveEaseOut], animations: {
                    self.cardsViews[0].center = self.likePoint
                }, completion: { _ in
                    self.cardsViews[0].removeFromSuperview()
                    self.cardsViews[1].removeFromSuperview()
                    
                    self.cardsViews.remove(at: 0)
                    
                    self.appendGestureRecognizer(to: self.cardsViews[0])
                    
                    let backCard = self.createCardFor(position: .back)
                    self.cardsViews.append(backCard)
                    
                    self.view.addSubview(self.cardsViews[1])
                    self.view.addSubview(self.cardsViews[0])
                })
            } else if translation.x < -100.0 { // When the user perfoms a PanGesture to the left, with a 100 points of distance from its origin, it perfoms a dislike
                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                    self.cardsViews[0].center = self.dislikePoint
                }, completion: { _ in
                    self.cardsViews[0].removeFromSuperview()
                    self.cardsViews.remove(at: 0)
                    
                    self.appendGestureRecognizer(to: self.cardsViews[0])
                    
                    let backCard = self.createCardFor(position: .back)
                    self.cardsViews.append(backCard)
                    
                    self.view.addSubview(self.cardsViews[1])
                    self.view.addSubview(self.cardsViews[0])
                })
            } else { //When the user ends a PanGesture, not dragging more than 100 points of distance from its origin to either sides, the front card will go back to its original state
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
                    self.cardsViews[0].center = self.cardsOrigin
                    self.cardsViews[0].transform = CGAffineTransform(rotationAngle: 0)
                }, completion: nil)
            }
            
        default:
            print("\(sender) state not handled")
        }
        
    }
    
    func setRoundedBorder(for view: UIView) {
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
    }
    
    func createCardFor(position: CardPosition) -> UIView {
        var scale: CGFloat!
        
        switch position {
        case .front:
            scale = 1
        case .back:
            scale = 0.9
        }
        
        let view = UIView()
        view.frame.size = CGSize(width: self.view.frame.width - 32, height: 400)
        view.center = self.cardsOrigin
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
        view.backgroundColor = colorsArr[Int(arc4random_uniform(UInt32(colorsArr.count)))]
        
        setRoundedBorder(for: view)
        
        return view
    }
    
    func appendGestureRecognizer(to view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_ :)))
        view.addGestureRecognizer(gesture)
    }
    
    func rotate(view:UIView, for translation:CGPoint) {
        let MAX_TRANSLATION: CGFloat = 100
        let MAX_ROTATION: CGFloat = 5 //Max rotation which a card might perform, in degrees
        
        //Higger absolute values than MAX_TRANSLATION are ignored
        let currentTranslationX = (translation.x >  MAX_TRANSLATION) || (translation.x <  -MAX_TRANSLATION) ? MAX_TRANSLATION : abs(translation.x)
        
        let absRotationAngle = ((currentTranslationX / 100.0) * MAX_ROTATION) * .pi / 180.0 //Calculates how much it will rotate, on radians
        
        //Based on PanGesture directions, it rotates the view
        if (translation.x > 0 && translation.y < 0) || (translation.x < 0 && translation.y > 0) {
            view.transform = CGAffineTransform(rotationAngle: absRotationAngle)
        } else if (translation.x < 0 && translation.y < 0) || (translation.x > 0 && translation.y > 0) {
            view.transform = CGAffineTransform(rotationAngle: -absRotationAngle)
        }
        
    }
}

