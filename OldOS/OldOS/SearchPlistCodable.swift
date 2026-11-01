//
//  SearchPlistCodable.swift
//  OldOS
//
//  Created by Zane Kleinberg on 3/28/21.
//



import Foundation

struct SearchData: Codable {
  struct PageType: Codable {
    struct TemplateParameters: Codable {
    }

    let templateName: String?
    let templateParameters: TemplateParameters?

    private enum CodingKeys: String, CodingKey {
      case templateName = "template-name"
      case templateParameters = "template-parameters"
    }
  }

    struct Items: Codable, Identifiable, Equatable {
        static func == (lhs: SearchData.Items, rhs: SearchData.Items) -> Bool {
            return lhs.id == rhs.id
        }
        
    let id = UUID()
    
    struct ArtworkUrls: Codable {
      let boxHeight: Int?
      let url: String?
      let boxWidth: Int?
      let scale: Int?
      let needsShine: Bool?

      private enum CodingKeys: String, CodingKey {
        case boxHeight = "box-height"
        case url
        case boxWidth = "box-width"
        case scale
        case needsShine = "needs-shine"
      }
    }

    struct StoreOffers: Codable {
      struct PLUS: Codable {
        struct AssetFlavors: Codable {
          struct HQ: Codable {
            let size: Int?
            let previewDuration: Int?
            let previewIsFaded: Bool?
            let previewURL: String?
            let duration: Int?

            private enum CodingKeys: String, CodingKey {
              case size
              case previewDuration = "preview-duration"
              case previewIsFaded = "preview-is-faded"
              case previewURL = "preview-url"
              case duration
            }
          }

          let hQ: HQ?

          private enum CodingKeys: String, CodingKey {
            case hQ = "HQ"
          }
        }

        let previewIsFaded: Bool?
        let priceDisplay: String?
        let price: Double?
        let actionDisplayName: String?
        let size: Int?
        let duration: Int?
        let previewDuration: Int?
        let buyParams: String?
        let previewURL: String?
        let assetFlavors: AssetFlavors?

        private enum CodingKeys: String, CodingKey {
          case previewIsFaded = "preview-is-faded"
          case priceDisplay = "price-display"
          case price
          case actionDisplayName = "action-display-name"
          case size
          case duration
          case previewDuration = "preview-duration"
          case buyParams = "buy-params"
          case previewURL = "preview-url"
          case assetFlavors = "asset-flavors"
        }
      }

      let pLUS: PLUS?

      private enum CodingKeys: String, CodingKey {
        case pLUS = "PLUS"
      }
    }

    struct Flavors: Codable {
      struct _2256: Codable {
        struct AssetFlavors: Codable {
          struct HQ: Codable {
            let size: Int?
            let previewDuration: Int?
            let previewIsFaded: Bool?
            let previewURL: String?
            let duration: Int?

            private enum CodingKeys: String, CodingKey {
              case size
              case previewDuration = "preview-duration"
              case previewIsFaded = "preview-is-faded"
              case previewURL = "preview-url"
              case duration
            }
          }

          let hQ: HQ?

          private enum CodingKeys: String, CodingKey {
            case hQ = "HQ"
          }
        }

        let previewIsFaded: Bool?
        let priceDisplay: String?
        let price: Double?
        let actionDisplayName: String?
        let size: Int?
        let duration: Int?
        let previewDuration: Int?
        let buyParams: String?
        let previewURL: String?
        let assetFlavors: AssetFlavors?

        private enum CodingKeys: String, CodingKey {
          case previewIsFaded = "preview-is-faded"
          case priceDisplay = "price-display"
          case price
          case actionDisplayName = "action-display-name"
          case size
          case duration
          case previewDuration = "preview-duration"
          case buyParams = "buy-params"
          case previewURL = "preview-url"
          case assetFlavors = "asset-flavors"
        }
      }

      let _2256: _2256?

      private enum CodingKeys: String, CodingKey {
        case _2256 = "2:256"
      }
    }

    struct Conditions: Codable {
      let value: String?
      let type: String?
      let `operator`: String?
      let conditionKey: String?

      private enum CodingKeys: String, CodingKey {
        case value
        case type
        case `operator`
        case conditionKey = "condition-key"
      }
    }

    struct Content: Codable {
      struct StoreOffers: Codable {
        struct PLUS: Codable {
          struct AssetFlavors: Codable {
            struct HQ: Codable {
              let size: Int?
              let previewDuration: Int?
              let previewIsFaded: Bool?
              let previewURL: String?
              let duration: Int?

              private enum CodingKeys: String, CodingKey {
                case size
                case previewDuration = "preview-duration"
                case previewIsFaded = "preview-is-faded"
                case previewURL = "preview-url"
                case duration
              }
            }

            let hQ: HQ?

            private enum CodingKeys: String, CodingKey {
              case hQ = "HQ"
            }
          }

          let previewIsFaded: Bool?
          let priceDisplay: String?
          let allowedToneStyles: [String]?
          let actionDisplayName: String?
          let price: Double?
          let duration: Int?
          let previewDuration: Int?
          let buyParams: String?
          let size: Int?
          let previewURL: String?
          let assetFlavors: AssetFlavors?

          private enum CodingKeys: String, CodingKey {
            case previewIsFaded = "preview-is-faded"
            case priceDisplay = "price-display"
            case allowedToneStyles = "allowed-tone-styles"
            case actionDisplayName = "action-display-name"
            case price
            case duration
            case previewDuration = "preview-duration"
            case buyParams = "buy-params"
            case size
            case previewURL = "preview-url"
            case assetFlavors = "asset-flavors"
          }
        }

        let pLUS: PLUS?

        private enum CodingKeys: String, CodingKey {
          case pLUS = "PLUS"
        }
      }

      struct ArtworkUrls: Codable {
        let boxHeight: Int?
        let url: String?
        let boxWidth: Int?
        let scale: Int?

        private enum CodingKeys: String, CodingKey {
          case boxHeight = "box-height"
          case url
          case boxWidth = "box-width"
          case scale
        }
      }

      struct Flavors: Codable {
        struct _2256: Codable {
          struct AssetFlavors: Codable {
            struct HQ: Codable {
              let size: Int?
              let previewDuration: Int?
              let previewIsFaded: Bool?
              let previewURL: String?
              let duration: Int?

              private enum CodingKeys: String, CodingKey {
                case size
                case previewDuration = "preview-duration"
                case previewIsFaded = "preview-is-faded"
                case previewURL = "preview-url"
                case duration
              }
            }

            let hQ: HQ?

            private enum CodingKeys: String, CodingKey {
              case hQ = "HQ"
            }
          }

          let previewIsFaded: Bool?
          let priceDisplay: String?
          let allowedToneStyles: [String]?
          let actionDisplayName: String?
          let price: Double?
          let duration: Int?
          let previewDuration: Int?
          let buyParams: String?
          let size: Int?
          let previewURL: String?
          let assetFlavors: AssetFlavors?

          private enum CodingKeys: String, CodingKey {
            case previewIsFaded = "preview-is-faded"
            case priceDisplay = "price-display"
            case allowedToneStyles = "allowed-tone-styles"
            case actionDisplayName = "action-display-name"
            case price
            case duration
            case previewDuration = "preview-duration"
            case buyParams = "buy-params"
            case size
            case previewURL = "preview-url"
            case assetFlavors = "asset-flavors"
          }
        }

        let _2256: _2256?

        private enum CodingKeys: String, CodingKey {
          case _2256 = "2:256"
        }
      }

      let type: String?
      let title: String?
      let userRatingCountString: String?
      let unmodifiedTitle: String?
      let trackNumber: Int?
      let storeOffers: StoreOffers?
      let itemID: Int?
      let releaseDate: Date?
      let artworkUrls: [ArtworkUrls]?
      let url: String?
      let flavors: Flavors?
      let urlPageType: String?
      let genreName: String?
      let title2: String?
      let artistName: String?
      let copyright: String?
      let collectionName: String?

      private enum CodingKeys: String, CodingKey {
        case type
        case title
        case userRatingCountString = "user-rating-count-string"
        case unmodifiedTitle = "unmodified-title"
        case trackNumber = "track-number"
        case storeOffers = "store-offers"
        case itemID = "item-id"
        case releaseDate = "release-date"
        case artworkUrls = "artwork-urls"
        case url
        case flavors
        case urlPageType = "url-page-type"
        case genreName = "genre-name"
        case title2
        case artistName = "artist-name"
        case copyright
        case collectionName = "collection-name"
      }
    }

    let type: String?
    let title: String?
    let title2: String?
    let urlPageType: String?
    let linkType: String?
    let artworkUrls: [ArtworkUrls]?
    let itemID: Int?
    let artistName: String?
    let userRatingCountString: String?
    let url: String?
    let userRatingCount: Int?
    let averageUserRating: Double?
    let containerName: String?
    let mediaType: String?
    let unmodifiedTitle: String?
    let trackNumber: Int?
    let storeOffers: StoreOffers?
    let releaseDate: Date?
    let flavors: Flavors?
    let genreName: String?
    let copyright: String?
    let collectionName: String?
    let `operator`: String?
    let conditions: [Conditions]?
    let content: Content?

    private enum CodingKeys: String, CodingKey {
      case type
      case title
      case title2
      case urlPageType = "url-page-type"
      case linkType = "link-type"
      case artworkUrls = "artwork-urls"
      case itemID = "item-id"
      case artistName = "artist-name"
      case userRatingCountString = "user-rating-count-string"
      case url
      case userRatingCount = "user-rating-count"
      case averageUserRating = "average-user-rating"
      case containerName = "container-name"
      case mediaType = "media-type"
      case unmodifiedTitle = "unmodified-title"
      case trackNumber = "track-number"
      case storeOffers = "store-offers"
      case releaseDate = "release-date"
      case flavors
      case genreName = "genre-name"
      case copyright
      case collectionName = "collection-name"
      case `operator`
      case conditions
      case content
    }
  }

  let pageType: PageType?
  let title: String?
  let items: [Items]?
  let storeVersion: String?

  private enum CodingKeys: String, CodingKey {
    case pageType = "page-type"
    case title
    case items
    case storeVersion = "store-version"
  }
}
