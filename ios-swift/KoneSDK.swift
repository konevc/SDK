// KoneSDK.swift
// Drop-in Special Offers tab for iOS apps
// Requirements: iOS 15+, Swift 5.7+
// Add to your project: File → Add Files → KoneSDK.swift

import UIKit

// MARK: - Config

public struct KoneSDKConfig {
    public let apiKey: String
    public let siteUrl: String
    public let greeting: String
    public let accentColor: UIColor
    public let quickChips: [(label: String, question: String)]

    public init(
        apiKey: String,
        siteUrl: String = "https://kone.vc",
        greeting: String? = nil,
        accentColor: UIColor = UIColor(red: 0.36, green: 0.43, blue: 0.96, alpha: 1),
        quickChips: [(label: String, question: String)]? = nil
    ) {
        self.apiKey = apiKey
        self.siteUrl = siteUrl
        self.greeting = greeting ?? "Hi! 👋 I'm your free personal AI assistant.\n\nI can help you find the best deals, offers and recommendations.\n\nTap a quick question or ask anything!"
        self.accentColor = accentColor
        self.quickChips = quickChips ?? [
            ("👟 Cheap shoes UK",   "Where can I buy cheap shoes in the UK?"),
            ("🤖 Top AI tools",     "Recommend top AI tools for 2025"),
            ("💰 Best deals today", "What are the best online deals today?"),
            ("✈️ Cheap travel",    "What are cheap travel destinations right now?"),
        ]
    }
}

// MARK: - Message model

private struct KoneMessage {
    let isAI: Bool
    let text: String
}

// MARK: - Main View Controller

public class KoneSpecialOffersViewController: UIViewController {

    private let config: KoneSDKConfig
    private var messages: [KoneMessage] = []
    private var responseId: String?
    private var isLoading = false

    // Landing
    private let landingScrollView = UIScrollView()
    private let landingStack = UIStackView()

    // Chat
    private let chatContainer = UIView()
    private let tableView = UITableView()
    private let inputBar = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var bottomConstraint: NSLayoutConstraint?

    public init(config: KoneSDKConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        self.title = "Special Offers"
        self.tabBarItem = UITabBarItem(title: "Special Offers", image: UIImage(systemName: "sparkles"), tag: 0)
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#0D0D10")
        buildLandingScreen()
        buildChatScreen()
        showLanding()
        observeKeyboard()
    }

    // MARK: - Landing

    private func buildLandingScreen() {
        landingScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(landingScrollView)
        NSLayoutConstraint.activate([
            landingScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            landingScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            landingScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            landingScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        landingStack.axis = .vertical
        landingStack.spacing = 0
        landingStack.translatesAutoresizingMaskIntoConstraints = false
        landingScrollView.addSubview(landingStack)
        NSLayoutConstraint.activate([
            landingStack.topAnchor.constraint(equalTo: landingScrollView.topAnchor),
            landingStack.leadingAnchor.constraint(equalTo: landingScrollView.leadingAnchor),
            landingStack.trailingAnchor.constraint(equalTo: landingScrollView.trailingAnchor),
            landingStack.bottomAnchor.constraint(equalTo: landingScrollView.bottomAnchor),
            landingStack.widthAnchor.constraint(equalTo: landingScrollView.widthAnchor),
        ])

        // Hero
        let heroView = makeHeroView()
        landingStack.addArrangedSubview(heroView)

        // Section label
        let label = UILabel()
        label.text = "QUICK QUESTIONS"
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor(hex: "#55535F")
        label.textAlignment = .left
        let labelWrap = padded(label, insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        landingStack.addArrangedSubview(labelWrap)

        // Chips
        let chipsStack = UIStackView()
        chipsStack.axis = .vertical
        chipsStack.spacing = 8
        for chip in config.quickChips {
            chipsStack.addArrangedSubview(makeChipButton(chip.label, question: chip.question))
        }
        let chipsWrap = padded(chipsStack, insets: UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16))
        landingStack.addArrangedSubview(chipsWrap)

        // CTA
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle("💬  Ask your own question", for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = config.accentColor
        ctaButton.layer.cornerRadius = 12
        ctaButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        ctaButton.addTarget(self, action: #selector(openChat), for: .touchUpInside)
        let ctaWrap = padded(ctaButton, insets: UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
        landingStack.addArrangedSubview(ctaWrap)

        // Footer
        landingStack.addArrangedSubview(makeKoneFooter())
    }

    private func makeHeroView() -> UIView {
        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIView()
        iconView.backgroundColor = config.accentColor
        iconView.layer.cornerRadius = 14
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let iconLabel = UILabel()
        iconLabel.text = "AI"
        iconLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        iconLabel.textColor = .white
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(iconLabel)
        iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor).isActive = true
        iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor).isActive = true

        let title = UILabel()
        title.text = "Your free personal\nAI assistant"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = UIColor(hex: "#EEEDF2")
        title.textAlignment = .center
        title.numberOfLines = 2

        let sub = UILabel()
        sub.text = "Find deals, offers & recommendations"
        sub.font = .systemFont(ofSize: 12)
        sub.textColor = UIColor(hex: "#55535F")
        sub.textAlignment = .center

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(sub)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        return container
    }

    private func makeChipButton(_ title: String, question: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13)
        btn.setTitleColor(UIColor(hex: "#9896A8"), for: .normal)
        btn.backgroundColor = UIColor(hex: "#1C1C22")
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor(hex: "#333340").cgColor
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 13, left: 14, bottom: 13, right: 14)
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.openChat(initialQuestion: question)
        }, for: .touchUpInside)
        return btn
    }

    // MARK: - Chat screen

    private func buildChatScreen() {
        chatContainer.backgroundColor = UIColor(hex: "#0D0D10")
        chatContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatContainer)

        // Chat header
        let header = makeChatHeader()
        chatContainer.addSubview(header)

        // Table
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.register(KoneMessageCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        chatContainer.addSubview(tableView)

        // Input bar
        buildInputBar()
        chatContainer.addSubview(inputBar)

        // Footer
        let footer = makeKoneFooter()
        chatContainer.addSubview(footer)

        bottomConstraint = inputBar.bottomAnchor.constraint(equalTo: chatContainer.safeAreaLayoutGuide.bottomAnchor)
        bottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            chatContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            header.topAnchor.constraint(equalTo: chatContainer.topAnchor),
            header.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
            inputBar.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: chatContainer.safeAreaLayoutGuide.bottomAnchor),
            footer.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
        ])
    }

    private func makeChatHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = UIColor(hex: "#141418")
        header.translatesAutoresizingMaskIntoConstraints = false
        header.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = UIColor(hex: "#9896A8")
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(showLanding), for: .touchUpInside)
        header.addSubview(backBtn)

        let avView = UIView()
        avView.backgroundColor = config.accentColor
        avView.layer.cornerRadius = 8
        avView.translatesAutoresizingMaskIntoConstraints = false
        let avLabel = UILabel()
        avLabel.text = "AI"
        avLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        avLabel.textColor = .white
        avLabel.translatesAutoresizingMaskIntoConstraints = false
        avView.addSubview(avLabel)
        header.addSubview(avView)

        let nameLabel = UILabel()
        nameLabel.text = "Your free personal AI assistant"
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = UIColor(hex: "#EEEDF2")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            backBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            avView.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 6),
            avView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            avView.widthAnchor.constraint(equalToConstant: 32),
            avView.heightAnchor.constraint(equalToConstant: 32),
            avLabel.centerXAnchor.constraint(equalTo: avView.centerXAnchor),
            avLabel.centerYAnchor.constraint(equalTo: avView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        return header
    }

    private func buildInputBar() {
        inputBar.backgroundColor = UIColor(hex: "#141418")
        inputBar.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = "Ask me anything…"
        textField.backgroundColor = UIColor(hex: "#1C1C22")
        textField.textColor = UIColor(hex: "#EEEDF2")
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(hex: "#333340").cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.returnKeyType = .send
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(textField)

        sendButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        sendButton.backgroundColor = config.accentColor
        sendButton.tintColor = .white
        sendButton.layer.cornerRadius = 10
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        inputBar.addSubview(sendButton)

        NSLayoutConstraint.activate([
            inputBar.heightAnchor.constraint(equalToConstant: 60),
            textField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            textField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 40),
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: - Actions

    @objc func openChat(initialQuestion: String? = nil) {
        landingScrollView.isHidden = true
        chatContainer.isHidden = false
        if messages.isEmpty {
            messages.append(KoneMessage(isAI: true, text: config.greeting))
            tableView.reloadData()
        }
        if let q = initialQuestion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.sendMessage(q) }
        }
    }

    @objc func showLanding() {
        landingScrollView.isHidden = false
        chatContainer.isHidden = true
    }

    @objc func handleSend() {
        guard let text = textField.text, !text.isEmpty else { return }
        textField.text = ""
        sendMessage(text)
    }

    private func sendMessage(_ prompt: String) {
        guard !isLoading else { return }
        isLoading = true
        sendButton.isEnabled = false
        messages.append(KoneMessage(isAI: false, text: prompt))
        tableView.reloadData()
        scrollToBottom()

        var body: [String: String] = ["prompt": prompt, "url": config.siteUrl, "api_key": config.apiKey]
        if let rid = responseId { body["response_id"] = rid }

        guard let url = URL(string: "https://go.kone.vc/mcp/chat"),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.sendButton.isEnabled = true
                if let error { self.appendAI("⚠️ Error: \(error.localizedDescription)"); return }
                guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.appendAI("⚠️ Invalid response"); return
                }
                if let rid = json["response_id"] as? String { self.responseId = rid }
                let msg = json["message"] as? String ?? json["response"] as? String ?? json["text"] as? String ?? "…"
                self.appendAI(msg)
            }
        }.resume()
    }

    private func appendAI(_ text: String) {
        messages.append(KoneMessage(isAI: true, text: text))
        tableView.reloadData()
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let ip = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: true)
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kbFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        bottomConstraint?.constant = -kbFrame.height
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        bottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - Helpers

    private func makeKoneFooter() -> UIView {
        let btn = UIButton(type: .system)
        btn.setTitle("More AI agents ↗", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 11)
        btn.setTitleColor(UIColor(hex: "#55535F"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        btn.addAction(UIAction { _ in UIApplication.shared.open(URL(string: "https://kone.vc/apps.html")!) }, for: .touchUpInside)
        return btn
    }

    private func padded(_ view: UIView, insets: UIEdgeInsets) -> UIView {
        let wrapper = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -insets.bottom),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -insets.right),
        ])
        return wrapper
    }
}

// MARK: - TableView

extension KoneSpecialOffersViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! KoneMessageCell
        cell.configure(with: messages[indexPath.row], accent: config.accentColor)
        return cell
    }
}

extension KoneSpecialOffersViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool { handleSend(); return true }
}

// MARK: - Message Cell

private class KoneMessageCell: UITableViewCell {
    private let bubble = UIView()
    private let label = UILabel()
    private let avView = UIView()
    private let avLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        bubble.layer.cornerRadius = 12
        bubble.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        avView.layer.cornerRadius = 6
        avView.translatesAutoresizingMaskIntoConstraints = false
        avView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        avView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        avLabel.font = .systemFont(ofSize: 8, weight: .heavy)
        avLabel.textColor = .white
        avLabel.text = "AI"
        avLabel.translatesAutoresizingMaskIntoConstraints = false
        avView.addSubview(avLabel)
        avLabel.centerXAnchor.constraint(equalTo: avView.centerXAnchor).isActive = true
        avLabel.centerYAnchor.constraint(equalTo: avView.centerYAnchor).isActive = true
        bubble.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 9),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -9),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with msg: KoneMessage, accent: UIColor) {
        subviews.forEach { if $0 != contentView { $0.removeFromSuperview() } }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        label.text = msg.text
        if msg.isAI {
            label.textColor = UIColor(hex: "#EEEDF2")
            bubble.backgroundColor = UIColor(hex: "#1C1C22")
            avView.backgroundColor = accent
            contentView.addSubview(avView)
            contentView.addSubview(bubble)
            NSLayoutConstraint.activate([
                avView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
                avView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubble.leadingAnchor.constraint(equalTo: avView.trailingAnchor, constant: 8),
                bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40),
                bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            ])
        } else {
            label.textColor = .white
            bubble.backgroundColor = accent
            contentView.addSubview(bubble)
            NSLayoutConstraint.activate([
                bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
                bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
                bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
                bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            ])
        }
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if s.count == 6 { s += "FF" }
        var val: UInt64 = 0
        Scanner(string: s).scanHexInt64(&val)
        self.init(red: CGFloat((val >> 24) & 0xFF)/255,
                  green: CGFloat((val >> 16) & 0xFF)/255,
                  blue: CGFloat((val >> 8) & 0xFF)/255,
                  alpha: CGFloat(val & 0xFF)/255)
    }
}
