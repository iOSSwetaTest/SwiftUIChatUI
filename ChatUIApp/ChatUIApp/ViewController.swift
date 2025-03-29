import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var enlargeButton: UIButton!
    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    var isFullScreen = false
    private var fontSize: CGFloat = 18.0
    private var debounceTimer: Timer?
    var images: [UIImage] = [] {
        didSet {
            collectionView.isHidden = images.isEmpty
            collectionView.reloadData()
            let temp: CGFloat = images.isEmpty ? 120 : 120 + 70
            if sheetHeight != temp {
                sheetHeight = temp
                self.sheetPresentationController?.animateChanges {
                    self.configureSheetPresentation()
                }
            }
        }
    }
    private var sheetHeight: CGFloat = 120
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sheetPresentationController?.prefersGrabberVisible = false
        self.presentationController?.delegate = self
        configureSheetPresentation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainerInset = .zero
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        // Ensure the modal presentation style is set
        self.modalPresentationStyle = .pageSheet
        // Add observers for keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        images = []
    }
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func enlargeAction(_ sender: UIButton) {
        isFullScreen.toggle()
        let name = !isFullScreen ? "arrow.up.left.and.arrow.down.right" :  "arrow.down.right.and.arrow.up.left"
        sender.setImage(UIImage(systemName: name), for: .normal)
        self.configureSheetPresentation()
        // Trigger an update to the presentation
        self.sheetPresentationController?.animateChanges {
            self.configureSheetPresentation()
        }
        if isFullScreen {
            fontSize = 18
            textView.font = .systemFont(ofSize: fontSize)
        } else {
            adjustFontSize()
        }
    }
    
    @IBAction private func openPhotoPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func configureSheetPresentation() {
        self.sheetPresentationController?.detents = [
            self.isFullScreen ? .large() : .custom { _ in  self.sheetHeight }
        ]
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            // Adjust the bottom constraint
            bottomConst.constant = keyboardHeight - view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
        
    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset the bottom constraint
        bottomConst.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func canFit(fontSize: CGFloat) -> Bool {
        let font = UIFont.systemFont(ofSize: fontSize)
        let textHeight = textView.text.height(withConstrainedWidth: textView.frame.width, font: font)
        let availableHeight = textView.frame.height
        return textHeight < (availableHeight * 0.66)
    }
    
    private func adjustFontSize() {
        if canFit(fontSize: fontSize) {
            if fontSize < 18, canFit(fontSize: fontSize + 2) {
                fontSize += 2
                textView.font = UIFont.systemFont(ofSize: fontSize)
            }
        } else {
            if fontSize > 14 {
                fontSize -= 2
                textView.font = UIFont.systemFont(ofSize: fontSize)
            }
            
        }
        // Enable scrolling if text exceeds the available space
        // textView.isScrollEnabled = textHeight > availableHeight
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        images.remove(at: indexPath.item)
    }
    
    
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Debounce font size adjustment
        guard !isFullScreen else {
            return
        }
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.adjustFontSize()
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Return false to prevent dismissal
        return false
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            images.append(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
