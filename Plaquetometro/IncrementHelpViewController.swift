//
//  IncrementHelpViewController.swift
//  Plaquetometro
//
//  Created by Igor Silva on 11/24/14.
//  Copyright (c) 2014 GARRA Software House. All rights reserved.
//

import UIKit

class IncrementHelpViewController: UIViewController, UITextFieldDelegate
{
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    @IBAction func btnFechar_TouchUpInside(sender: UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}