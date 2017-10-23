//
//  SplitViewController.swift
//  Example
//
//  Created by Kacper Harasim on 03.10.2016.
//  Copyright © 2016 Polidea. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
    }

    func splitViewController(splitViewController _: UISplitViewController, collapseSecondaryViewController _: UIViewController, ontoPrimaryViewController _: UIViewController) -> Bool {
        return true
    }
}
