import Foundation
import AppKit
import UniformTypeIdentifiers

@available(macOS 11.0, *)
@available(macOSApplicationExtension 11.0, *)
open class ShareHandlerMacosViewController: NSViewController {
    static var hostAppBundleIdentifier = ""
    static var appGroupId = ""
    let sharedKey = "ShareKey"
    var sharedText: [String] = []
    let urlContentType = UTType.url.identifier
    let fileURLType = UTType.fileURL.identifier
    let textContentType = UTType.text.identifier
    var sharedAttachments: [SharedAttachment] = []
    var usedFileNames: Set<String> = []
    lazy var userDefaults: UserDefaults = {
        return UserDefaults(suiteName: ShareHandlerMacosViewController.appGroupId)!
    }()

    public func loadIds() {
        let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!

        let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".")
        ShareHandlerMacosViewController.hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!])

        ShareHandlerMacosViewController.appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String) ?? "group.\(ShareHandlerMacosViewController.hostAppBundleIdentifier)"
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadIds()
        Task {
            await handleInputItems()
            extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func handleInputItems() async {
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    do {
                        if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
                            try await handleUrl(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(fileURLType) {
                            try await handleFiles(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
                            try await handleText(content: content, attachment: attachment, index: index)
                        } else {
                            print("Attachment not handled with registered type identifiers: \(attachment.registeredTypeIdentifiers)")
                        }
                    } catch {
                        print("[ERROR] Error handling attachment: \(error)")
                    }
                }
            }
            redirectToHostApp()
        }
    }

    public func handleText(content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: textContentType, options: nil)
        if let item = data as? String {
            sharedText.append(item)
        }
    }

    public func handleUrl(content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: urlContentType, options: nil)
        if let item = data as? URL {
            sharedText.append(item.absoluteString)
        }
    }

    public func handleFiles(content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: fileURLType, options: nil)
        if let url = data as? URL {
            let fileName = getFileName(from: url, type: .file)
            let newFileUrl = getNewFileUrl(fileName: fileName)
            let copied = copyFile(at: url, to: newFileUrl)
            if (copied) {
                sharedAttachments.append(SharedAttachment.init(path: newFileUrl.absoluteString, type: .file))
            }
        }
    }

    public func getNewFileUrl(fileName: String) -> URL {
        let newFileUrl = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ShareHandlerMacosViewController.appGroupId)!
            .appendingPathComponent(fileName)
        return newFileUrl
    }

    public func redirectToHostApp() {
        loadIds()
        let url = URL(string: "ShareMedia-\(ShareHandlerMacosViewController.hostAppBundleIdentifier)://\(ShareHandlerMacosViewController.hostAppBundleIdentifier)?key=\(sharedKey)")

        let sharedMedia = SharedMedia.init(
            attachments: sharedAttachments,
            conversationIdentifier: nil,
            content: sharedText.joined(separator: "\n"),
            speakableGroupName: nil,
            serviceName: nil,
            senderIdentifier: nil,
            imageFilePath: nil,
            subject: nil
        )

        let json = sharedMedia.toJson()
        userDefaults.set(json, forKey: sharedKey)
        userDefaults.synchronize()

        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }

    func getFileName(from url: URL, type: SharedAttachmentType) -> String {
        var name = url.lastPathComponent
        if (name.isEmpty) {
            name = UUID().uuidString + "." + getExtension(from: url, type: type)
        }

        var finalName = name
        var counter = 1
        while usedFileNames.contains(finalName) {
            let nameWithoutExtension = (name as NSString).deletingPathExtension
            let fileExtension = (name as NSString).pathExtension
            if fileExtension.isEmpty {
                finalName = "\(nameWithoutExtension) (\(counter))"
            } else {
                finalName = "\(nameWithoutExtension) (\(counter)).\(fileExtension)"
            }
            counter += 1
        }
        usedFileNames.insert(finalName)
        return finalName
    }

    func getExtension(from url: URL, type: SharedAttachmentType) -> String {
        let parts = url.lastPathComponent.components(separatedBy: ".")
        var ex: String? = nil
        if (parts.count > 1) {
            ex = parts.last
        }
        if (ex == nil) {
            switch type {
            case .image:
                ex = "PNG"
            case .video:
                ex = "MP4"
            case .file:
                ex = "TXT"
            default:
                ex = ""
            }
        }
        return ex ?? "Unknown"
    }

    func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
}
