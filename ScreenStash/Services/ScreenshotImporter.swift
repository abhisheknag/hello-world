import Foundation
import Photos
import UIKit

actor ScreenshotImporter {

    struct ImportedAsset {
        let localIdentifier: String
        let creationDate: Date
        let image: UIImage
        let thumbnailData: Data?
    }

    private let thumbnailSize = CGSize(width: 200, height: 200)

    /// Request photo library authorization
    static func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Fetch all screenshot assets, optionally only those created after a given date
    func fetchScreenshots(after date: Date? = nil) async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = [
            NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        ]

        if let date {
            predicates.append(NSPredicate(format: "creationDate > %@", date as NSDate))
        }

        fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Load full image from a PHAsset
    func loadImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Load a small thumbnail from a PHAsset
    func loadThumbnail(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                let data = image?.jpegData(compressionQuality: 0.6)
                continuation.resume(returning: data)
            }
        }
    }

    /// Observe photo library changes
    func registerChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PHPhotoLibrary.shared().register(observer)
    }

    func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PHPhotoLibrary.shared().unregisterChangeObserver(observer)
    }
}
