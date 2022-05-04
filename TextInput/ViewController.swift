//
//  ViewController.swift
//  TextInput
//
//  Created by Ziqiao Chen on 9/9/20.
//

import UIKit
import Combine

class ViewController: UIViewController {

    private var keyboardSubscriptions: AnyCancellable?

    var scrollView: UIScrollView!
    var textInputView: TextInputView!

    override func viewDidLoad() {
        super.viewDidLoad()

        textInputView = TextInputView()
        textInputView.backgroundColor = .systemYellow
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.addSubview(textInputView)
        view.addSubview(scrollView)

        // Set up auto layout constraints
        //
        NSLayoutConstraint.activate([
            textInputView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            textInputView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            textInputView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            textInputView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -10)
        ])
        
        // Set up gesture recognizer.
        //
        //let selector = #selector(type(of: self).tapHandler(_:))
        //let tapRecognizer = UITapGestureRecognizer(target: self, action: selector)
        //textInputView.addGestureRecognizer(tapRecognizer)
        
        let interaction = UITextInteraction(for: .editable)
        interaction.textInput = textInputView
        textInputView.addInteraction(interaction)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create keyboard willShow/Hide notification publisher.
        //
        let publishers = [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillHideNotification].map {
            NotificationCenter.default.publisher(for: $0)
        }

        // Adjust scrollView.contentInset.bottom based on the keyboard height.
        //
        keyboardSubscriptions = Publishers.MergeMany(publishers).sink { notification in
            var newContentInset = UIEdgeInsets.zero
            if notification.name == UIResponder.keyboardWillShowNotification,
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keybardHeight = frame.cgRectValue.size.height
                newContentInset = UIEdgeInsets(top: 0, left: 0, bottom: keybardHeight, right: 0)
            }
            self.scrollView.contentInset = newContentInset
            self.scrollView.contentSize = self.textInputView.frame.size
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardSubscriptions?.cancel() // Cancel the subscription.
    }
    
    @objc public func tapHandler(_ sender: UITapGestureRecognizer) {
        textInputView.becomeFirstResponder()
    }
}

