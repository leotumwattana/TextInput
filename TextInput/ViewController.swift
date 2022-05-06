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

    var textInputView: TextInputView!

    override func viewDidLoad() {
        super.viewDidLoad()

        textInputView = TextInputView()
        textInputView.backgroundColor = .systemYellow
        view.addSubview(textInputView)
        
        // Set up auto layout constraints
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textInputView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 10),
            textInputView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -10),
            textInputView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 10),
            textInputView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -10)
        ])
        
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        textInputView.keyboardDismissMode = .interactive
        
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
            self.textInputView.contentInset = newContentInset
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardSubscriptions?.cancel() // Cancel the subscription.
    }
}

