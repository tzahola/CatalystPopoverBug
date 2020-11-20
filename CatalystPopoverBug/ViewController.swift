//
//  ViewController.swift
//  CatalystPopoverBug
//
//  Created by Tamás Zahola on 2020. 11. 20..
//

import UIKit

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(origin: center.applying(CGAffineTransform(translationX: -size.width / 2, y: -size.height / 2)), size: size)
    }

    var center: CGPoint { CGPoint(x: minX + width / 2, y: minY + height / 2) }
}

class ChildViewController: UIViewController {
    private weak var owner: ViewController!

    init(owner: ViewController) {
        super.init(nibName: nil, bundle: nil)
        self.owner = owner
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        class View: UIView {
            override func didMoveToWindow() {
                super.didMoveToWindow() // put a breakpoint here to observe UIKit removing the child VCs view
            }
        }
        view = View(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 300, height: 300)
        view.backgroundColor = .yellow

        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(switchPresentation(_:)), for: .touchUpInside)
        button.setTitle("Switch between child ⟷ popover", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     button.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }

    @objc
    private func switchPresentation(_ sender: UIButton) {
        owner.switchPresentation(self)
    }
}

class ViewController: UIViewController {
    private var childViewController: ChildViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        childViewController = ChildViewController(owner: self)
        addAsChild()
    }

    fileprivate func switchPresentation(_ viewController: ChildViewController) {
        if viewController.presentingViewController != nil {
            viewController.dismiss(animated: true) {
                // Calling addAsChild() directly won't work on macOS 11.0.1
                DispatchQueue.main.async {
                    self.addAsChild()
                }
            }
        } else {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()

            // Calling presentAsPopover() directly (or even with DispatchQueue.main.async) would print the "unbalanced begin/end appearance transitions" warning to the console
            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
                self.presentAsPopover()
            }
        }
    }

    private func presentAsPopover() {
        childViewController.modalPresentationStyle = .popover
        childViewController.popoverPresentationController!.sourceView = view
        childViewController.popoverPresentationController!.sourceRect = CGRect(center: view.bounds.center, size: CGSize(width: 10, height: 10))
        present(childViewController, animated: true, completion: nil)
    }

    private func addAsChild() {
        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = true
        childViewController.view.frame = CGRect(center: view.bounds.center, size: childViewController.preferredContentSize)
        childViewController.didMove(toParent: self)
    }
}

