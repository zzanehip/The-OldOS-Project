import SwiftUI
import Foundation
import Combine
import UserNotifications
import AudioToolbox
import UIKit
import AVFoundation
import MediaPlayer

enum RetroClockTab: Int, CaseIterable {
    case world, alarm, stopwatch, timer

    var title: String {
        switch self {
        case .world: return "World Clock"
        case .alarm: return "Alarm"
        case .stopwatch: return "Stopwatch"
        case .timer: return "Timer"
        }
    }

    var symbol: String {
        switch self {
        case .world: return "clock-BarWorldClockTemplate"
        case .alarm: return "clock-BarAlarmTemplate"
        case .stopwatch: return "clock-BarStopwatchTemplate"
        case .timer: return "clock-BarTimerTemplate"
        }
    }

}

struct RetroClockCity: Codable, Identifiable, Equatable {
    let name: String
    let zone: String
    var id: String { name + "|" + zone }

    var timeZone: TimeZone { TimeZone(identifier: zone) ?? .current }

    var country: String? = nil
    var searchName: String {
        let region = country ?? Self.choices.first(where: { $0.name == name })?.country ?? ""
        return region.isEmpty ? name : name + ", " + region
    }
    // Apple's complete iOS 4.3 AppSupport city catalog, not timezone guesses.
    static let choices: [RetroClockCity] = [
        .init(name: "Abidjan", zone: "Africa/Bamako", country: "Ivory Coast"),
        .init(name: "Abu Dhabi", zone: "Asia/Dubai", country: "U.A.E."),
        .init(name: "Accra", zone: "Africa/Accra", country: "Ghana"),
        .init(name: "Adak", zone: "America/Adak", country: "U.S.A."),
        .init(name: "Addis Ababa", zone: "Africa/Addis_Ababa", country: "Ethiopia"),
        .init(name: "Adelaide", zone: "Australia/Adelaide", country: "Australia"),
        .init(name: "Albuquerque", zone: "US/Mountain", country: "U.S.A."),
        .init(name: "Algiers", zone: "Africa/Algiers", country: "Algeria"),
        .init(name: "Amman", zone: "Asia/Amman", country: "Jordan"),
        .init(name: "Amsterdam", zone: "Europe/Amsterdam", country: "Netherlands"),
        .init(name: "Anadyr", zone: "Asia/Anadyr", country: "Russia"),
        .init(name: "Antananarivo", zone: "Indian/Antananarivo", country: "Madagascar"),
        .init(name: "Anchorage", zone: "America/Anchorage", country: "U.S.A."),
        .init(name: "Ankara", zone: "Europe/Istanbul", country: "Turkey"),
        .init(name: "Ashgabat", zone: "Asia/Ashgabat", country: "Turkmenistan"),
        .init(name: "Asmera", zone: "Africa/Asmera", country: "Eritrea"),
        .init(name: "Astana", zone: "Asia/Almaty", country: "Kazakhstan"),
        .init(name: "Asuncion", zone: "America/Asuncion", country: "Paraguay"),
        .init(name: "Athens", zone: "Europe/Athens", country: "Greece"),
        .init(name: "Atlanta", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Auckland", zone: "Pacific/Auckland", country: "New Zealand"),
        .init(name: "Austin", zone: "US/Central", country: "U.S.A."),
        .init(name: "Baghdad", zone: "Asia/Baghdad", country: "Iraq"),
        .init(name: "Baku", zone: "Asia/Baku", country: "Azerbaijan"),
        .init(name: "Baltimore", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Bamako", zone: "Africa/Bamako", country: "Mali"),
        .init(name: "Bangkok", zone: "Asia/Bangkok", country: "Thailand"),
        .init(name: "Bangui", zone: "Africa/Bangui", country: "Central African Republic"),
        .init(name: "Barcelona", zone: "Europe/Madrid", country: "Spain"),
        .init(name: "Bari", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Basse-Terre", zone: "America/Guadeloupe", country: "Guadeloupe"),
        .init(name: "Beijing", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Beirut", zone: "Asia/Beirut", country: "Lebanon"),
        .init(name: "Belgrade", zone: "Europe/Belgrade", country: "Serbia"),
        .init(name: "Belize City", zone: "America/Belize", country: "Belize"),
        .init(name: "Benicia", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Berkeley", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Berlin", zone: "Europe/Berlin", country: "Germany"),
        .init(name: "Bern", zone: "Europe/Zurich", country: "Switzerland"),
        .init(name: "Bishkek", zone: "Asia/Bishkek", country: "Kyrgyzstan"),
        .init(name: "Bissau", zone: "Africa/Bissau", country: "Guinea Bissau"),
        .init(name: "Blacksburg", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Bogota", zone: "America/Bogota", country: "Colombia"),
        .init(name: "Bologna", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Boston", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Bratislava", zone: "Europe/Bratislava", country: "Slovakia"),
        .init(name: "Brasalia", zone: "Brazil/East", country: "Brazil"),
        .init(name: "Bridgetown", zone: "America/Barbados", country: "Barbados"),
        .init(name: "Brisbane", zone: "Australia/Brisbane", country: "Australia"),
        .init(name: "Brussels", zone: "Europe/Brussels", country: "Belgium"),
        .init(name: "Bucharest", zone: "Europe/Bucharest", country: "Romania"),
        .init(name: "Budapest", zone: "Europe/Budapest", country: "Hungary"),
        .init(name: "Buenos Aires", zone: "America/Buenos_Aires", country: "Argentina"),
        .init(name: "Burlingame", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Cairo", zone: "Africa/Cairo", country: "Egypt"),
        .init(name: "Calgary", zone: "Canada/Mountain", country: "Canada"),
        .init(name: "Canary Islands", zone: "Atlantic/Canary", country: "Spain"),
        .init(name: "Canberra", zone: "Australia/Canberra", country: "Australia"),
        .init(name: "Canton", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Cape Town", zone: "Africa/Johannesburg", country: "South Africa"),
        .init(name: "Caracas", zone: "America/Caracas", country: "Venezuela"),
        .init(name: "Cardiff", zone: "Europe/London", country: "Wales"),
        .init(name: "Catanzaro", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Cayenne", zone: "America/Cayenne", country: "French Guiana"),
        .init(name: "Charlotte", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Charlotte Amalie", zone: "America/Virgin", country: "U.S. Virgin Islands"),
        .init(name: "Chennai", zone: "Asia/Calcutta", country: "India"),
        .init(name: "Chicago", zone: "America/Chicago", country: "U.S.A."),
        .init(name: "Chisinau", zone: "Europe/Chisinau", country: "Moldova"),
        .init(name: "Chita", zone: "Asia/Yakutsk", country: "Russia"),
        .init(name: "Cleveland", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Colombo", zone: "Asia/Colombo", country: "Sri Lanka"),
        .init(name: "Columbus", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Conakry", zone: "Africa/Conakry", country: "Guinea"),
        .init(name: "Copenhagen", zone: "Europe/Copenhagen", country: "Denmark"),
        .init(name: "Cupertino", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Cork", zone: "Europe/Dublin", country: "Ireland"),
        .init(name: "Crotone", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Dhaka", zone: "Asia/Dhaka", country: "Bangladesh"),
        .init(name: "Dakar", zone: "Africa/Dakar", country: "Senegal"),
        .init(name: "Dallas", zone: "US/Central", country: "U.S.A."),
        .init(name: "Daly City", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Damascus", zone: "Asia/Damascus", country: "Syria"),
        .init(name: "Dar es Salaam", zone: "Africa/Dar_es_Salaam", country: "Tanzania"),
        .init(name: "Darwin", zone: "Australia/Darwin", country: "Australia"),
        .init(name: "Denver", zone: "America/Denver", country: "U.S.A."),
        .init(name: "Detroit", zone: "America/Detroit", country: "U.S.A."),
        .init(name: "Djibouti", zone: "Africa/Djibouti", country: "Djibouti"),
        .init(name: "Doha", zone: "Asia/Qatar", country: "Qatar"),
        .init(name: "Douala", zone: "Africa/Douala", country: "Cameroon"),
        .init(name: "Dubai", zone: "Asia/Dubai", country: "U.A.E."),
        .init(name: "Dublin", zone: "Europe/Dublin", country: "Ireland"),
        .init(name: "Dushanbe", zone: "Asia/Dushanbe", country: "Tajikistan"),
        .init(name: "Edinburgh", zone: "Europe/London", country: "Scotland"),
        .init(name: "El Paso", zone: "US/Mountain", country: "U.S.A."),
        .init(name: "Florence", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Fremont", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Fort-de-France", zone: "America/Martinique", country: "Martinique"),
        .init(name: "Foster City", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Freetown", zone: "Africa/Freetown", country: "Sierra Leone"),
        .init(name: "Gaborone", zone: "Africa/Gaborone", country: "Botswana"),
        .init(name: "Galápagos Islands", zone: "Pacific/Galapagos", country: "Ecuador"),
        .init(name: "Geneva", zone: "Europe/Zurich", country: "Switzerland"),
        .init(name: "Genoa", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Georgetown", zone: "America/Guyana", country: "Guyana"),
        .init(name: "Grytviken", zone: "Atlantic/South_Georgia", country: "South Georgia"),
        .init(name: "Guam", zone: "Pacific/Guam", country: "U.S.A."),
        .init(name: "Guatemala City", zone: "America/Guatemala", country: "Guatemala"),
        .init(name: "Gustavia", zone: "America/St_Barthelemy", country: "Saint Barthelemy"),
        .init(name: "Halifax", zone: "Canada/Atlantic", country: "Canada"),
        .init(name: "Hamburg", zone: "Europe/Berlin", country: "Germany"),
        .init(name: "Easter Island", zone: "Pacific/Easter", country: "Chile"),
        .init(name: "Hanoi", zone: "Asia/Saigon", country: "Vietnam"),
        .init(name: "Harare", zone: "Africa/Harare", country: "Zimbabwe"),
        .init(name: "Havana", zone: "America/Havana", country: "Cuba"),
        .init(name: "Healdsburg", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Helsinki", zone: "Europe/Helsinki", country: "Finland"),
        .init(name: "Hobart", zone: "Australia/Hobart", country: "Australia"),
        .init(name: "Hong Kong", zone: "Asia/Hong_Kong", country: "China"),
        .init(name: "Honolulu", zone: "Pacific/Honolulu", country: "U.S.A."),
        .init(name: "Houston", zone: "US/Central", country: "U.S.A."),
        .init(name: "Indianapolis", zone: "America/Indianapolis", country: "U.S.A."),
        .init(name: "Irkutsk", zone: "Asia/Irkutsk", country: "Russia"),
        .init(name: "Islamabad", zone: "Asia/Karachi", country: "Pakistan"),
        .init(name: "Istanbul", zone: "Europe/Istanbul", country: "Turkey"),
        .init(name: "Jakarta", zone: "Asia/Jakarta", country: "Indonesia"),
        .init(name: "Jerusalem", zone: "Asia/Jerusalem", country: "Israel"),
        .init(name: "Johannesburg", zone: "Africa/Johannesburg", country: "South Africa"),
        .init(name: "Kabul", zone: "Asia/Kabul", country: "Afghanistan"),
        .init(name: "Kaliningrad", zone: "Europe/Kaliningrad", country: "Russia"),
        .init(name: "Kampala", zone: "Africa/Kampala", country: "Uganda"),
        .init(name: "Katmandu", zone: "Asia/Katmandu", country: "Nepal"),
        .init(name: "Khartoum", zone: "Africa/Khartoum", country: "Sudan"),
        .init(name: "Kiev", zone: "Europe/Kiev", country: "Ukraine"),
        .init(name: "Kingston", zone: "Jamaica", country: "Jamaica"),
        .init(name: "Kinshasa", zone: "Africa/Kinshasa", country: "Zaire"),
        .init(name: "Knoxville", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Kolkata", zone: "Asia/Calcutta", country: "India"),
        .init(name: "Krasnoyarsk", zone: "Asia/Krasnoyarsk", country: "Russia"),
        .init(name: "Kuala Lumpur", zone: "Asia/Kuala_Lumpur", country: "Malaysia"),
        .init(name: "Kuwait", zone: "Asia/Kuwait", country: "Kuwait"),
        .init(name: "Kyiv", zone: "Asia/Amman", country: "Ukraine"),
        .init(name: "La Paz", zone: "America/La_Paz", country: "Bolivia"),
        .init(name: "Lagos", zone: "Africa/Lagos", country: "Nigeria"),
        .init(name: "Las Vegas", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Lima", zone: "America/Lima", country: "Peru"),
        .init(name: "Lisbon", zone: "Europe/Lisbon", country: "Portugal"),
        .init(name: "Little Rock", zone: "US/Central", country: "U.S.A."),
        .init(name: "Ljubljana", zone: "Europe/Ljubljana", country: "Slovenia"),
        .init(name: "London", zone: "Europe/London", country: "England"),
        .init(name: "Longhua", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Los Altos", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Los Angeles", zone: "America/Los_Angeles", country: "U.S.A."),
        .init(name: "Los Gatos", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Louisville", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Luanda", zone: "Africa/Luanda", country: "Angola"),
        .init(name: "Lusaka", zone: "Africa/Lusaka", country: "Zambia"),
        .init(name: "Luxembourg", zone: "Europe/Luxembourg", country: "Luxembourg"),
        .init(name: "Macau", zone: "Asia/Macau", country: "China"),
        .init(name: "Madison", zone: "US/Central", country: "U.S.A."),
        .init(name: "Madrid", zone: "Europe/Madrid", country: "Spain"),
        .init(name: "Malabo", zone: "Africa/Malabo", country: "Equatorial Guinea"),
        .init(name: "Male", zone: "Indian/Maldives", country: "Maldives"),
        .init(name: "Managua", zone: "America/Managua", country: "Nicaragua"),
        .init(name: "Manama", zone: "Asia/Bahrain", country: "Bahrain"),
        .init(name: "Marigot", zone: "America/Marigot", country: "Saint Martin"),
        .init(name: "Manila", zone: "Asia/Manila", country: "Philippines"),
        .init(name: "Maputo", zone: "Africa/Maputo", country: "Mozambique"),
        .init(name: "Mecca", zone: "Asia/Riyadh", country: "Saudi Arabia"),
        .init(name: "Melbourne", zone: "Australia/Melbourne", country: "Australia"),
        .init(name: "Memphis", zone: "US/Central", country: "U.S.A."),
        .init(name: "Menlo Park", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Messina", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Mexico City", zone: "America/Mexico_City", country: "Mexico"),
        .init(name: "Miami", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Milan", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Milbank", zone: "US/Central", country: "U.S.A."),
        .init(name: "Milwaukee", zone: "US/Central", country: "U.S.A."),
        .init(name: "Minneapolis", zone: "US/Central", country: "U.S.A."),
        .init(name: "Minsk", zone: "Europe/Minsk", country: "Belarus"),
        .init(name: "Magadan", zone: "Asia/Magadan", country: "Russia"),
        .init(name: "Mogadishu", zone: "Africa/Mogadishu", country: "Somalia"),
        .init(name: "Monrovia", zone: "Africa/Monrovia", country: "Liberia"),
        .init(name: "Montevideo", zone: "America/Montevideo", country: "Uruguay"),
        .init(name: "Montpelier", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Montreal", zone: "America/Montreal", country: "Canada"),
        .init(name: "Moscow", zone: "Europe/Moscow", country: "Russia"),
        .init(name: "Monterey", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Mountain View", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Mumbai", zone: "Asia/Calcutta", country: "India"),
        .init(name: "Munich", zone: "Europe/Berlin", country: "Germany"),
        .init(name: "Muscat", zone: "Asia/Muscat", country: "Oman"),
        .init(name: "Napa", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Naples", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Nairobi", zone: "Africa/Nairobi", country: "Kenya"),
        .init(name: "Naters", zone: "Europe/Zurich", country: "Switzerland"),
        .init(name: "Ndjamena", zone: "Africa/Ndjamena", country: "Chad"),
        .init(name: "New Delhi", zone: "Asia/Calcutta", country: "India"),
        .init(name: "New Orleans", zone: "US/Central", country: "U.S.A."),
        .init(name: "New York", zone: "America/New_York", country: "U.S.A."),
        .init(name: "Niamey", zone: "Africa/Niamey", country: "Niger"),
        .init(name: "Nouakchott", zone: "Africa/Nouakchott", country: "Mauritania"),
        .init(name: "Noumea", zone: "Pacific/Noumea", country: "New Caledonia"),
        .init(name: "Novato", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Novosibirsk", zone: "Asia/Novosibirsk", country: "Russia"),
        .init(name: "Nukuʻalofa", zone: "Pacific/Tongatapu", country: "Tonga"),
        .init(name: "Nuuk", zone: "America/Godthab", country: "Greenland"),
        .init(name: "Oakland", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Oklahoma City", zone: "US/Central", country: "U.S.A."),
        .init(name: "Omaha", zone: "US/Central", country: "U.S.A."),
        .init(name: "Omsk", zone: "Asia/Omsk", country: "Russia"),
        .init(name: "Osaka", zone: "Asia/Tokyo", country: "Japan"),
        .init(name: "Oslo", zone: "Europe/Oslo", country: "Norway"),
        .init(name: "Ottawa", zone: "Canada/Eastern", country: "Canada"),
        .init(name: "Ouagadougou", zone: "Africa/Ouagadougou", country: "Burkina Faso"),
        .init(name: "Pacifica", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Pago Pago", zone: "Pacific/Pago_Pago", country: "Samoa"),
        .init(name: "Palermo", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Palo Alto", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Panama City", zone: "America/Panama", country: "Panama"),
        .init(name: "Tahiti", zone: "Pacific/Tahiti", country: "French Polynesia"),
        .init(name: "Paramaribo", zone: "America/Paramaribo", country: "Surinam"),
        .init(name: "Paris", zone: "Europe/Paris", country: "France"),
        .init(name: "Perm", zone: "Asia/Yekaterinburg", country: "Russia"),
        .init(name: "Perth", zone: "Australia/Perth", country: "Australia"),
        .init(name: "Petaluma", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Philadelphia", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Phnom Penh", zone: "Asia/Phnom_Penh", country: "Cambodia"),
        .init(name: "Phoenix", zone: "America/Phoenix", country: "U.S.A."),
        .init(name: "Pittsburgh", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Pleasanton", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Podgorica", zone: "Europe/Podgorica", country: "Montenegro"),
        .init(name: "Ponta Delgada", zone: "Atlantic/Azores", country: "Portugal"),
        .init(name: "Port Louis", zone: "Indian/Mauritius", country: "Mauritius"),
        .init(name: "Port-au-Prince", zone: "America/Port-au-Prince", country: "Haiti"),
        .init(name: "Portland", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Prague", zone: "Europe/Prague", country: "Czech Republic"),
        .init(name: "Pyongyang", zone: "Asia/Pyongyang", country: "North Korea"),
        .init(name: "Quito", zone: "America/Guayaquil", country: "Ecuador"),
        .init(name: "Rabat", zone: "Africa/Casablanca", country: "Morocco"),
        .init(name: "Rangoon", zone: "Asia/Rangoon", country: "Burma"),
        .init(name: "Recife", zone: "America/Recife", country: "Brazil"),
        .init(name: "Redwood City", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Regina", zone: "Canada/Saskatchewan", country: "Canada"),
        .init(name: "Reykjavik", zone: "Atlantic/Reykjavik", country: "Iceland"),
        .init(name: "Riga", zone: "Europe/Riga", country: "Latvia"),
        .init(name: "Rio de Janeiro", zone: "Brazil/East", country: "Brazil"),
        .init(name: "Riyadh", zone: "Asia/Riyadh", country: "Saudi Arabia"),
        .init(name: "Rome", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Saint-Denis", zone: "Indian/Reunion", country: "Reunion Island"),
        .init(name: "Salt Lake City", zone: "US/Mountain", country: "U.S.A."),
        .init(name: "Samara", zone: "Europe/Samara", country: "Russia"),
        .init(name: "San Diego", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Antonio", zone: "US/Central", country: "U.S.A."),
        .init(name: "San Bruno", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Carlos", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Francisco", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "SanJoseCA", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Jose", zone: "America/Costa_Rica", country: "Costa Rica"),
        .init(name: "San Juan", zone: "America/Puerto_Rico", country: "Puerto Rico"),
        .init(name: "San Leandro", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Salvador", zone: "America/El_Salvador", country: "El Salvador"),
        .init(name: "SanMarino", zone: "Europe/Rome", country: "Italy"),
        .init(name: "San Mateo", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Pablo", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Rafael", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "San Ramon", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Santa Clara", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Santa Cruz", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Sanaa", zone: "Asia/Aden", country: "Yemen"),
        .init(name: "Santiago", zone: "America/Santiago", country: "Chile"),
        .init(name: "Santo Domingo", zone: "America/Santo_Domingo", country: "Dominican Republic"),
        .init(name: "Sao Paulo", zone: "America/Sao_Paulo", country: "Brazil"),
        .init(name: "Seattle", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Seoul", zone: "Asia/Seoul", country: "Korea"),
        .init(name: "Shanghai", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Shenzhen", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Singapore", zone: "Asia/Singapore", country: "Singapore"),
        .init(name: "Sioux Falls", zone: "US/Central", country: "U.S.A."),
        .init(name: "Skopje", zone: "Europe/Skopje", country: "Macedonia"),
        .init(name: "Sofia", zone: "Europe/Sofia", country: "Bulgaria"),
        .init(name: "St. John's", zone: "Canada/Newfoundland", country: "Canada"),
        .init(name: "St. Louis", zone: "US/Central", country: "U.S.A."),
        .init(name: "St. Petersburg", zone: "Europe/Moscow", country: "Russia"),
        .init(name: "Sunnyvale", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Stockholm", zone: "Europe/Stockholm", country: "Sweden"),
        .init(name: "Suva", zone: "Pacific/Fiji", country: "Fiji"),
        .init(name: "Sydney", zone: "Australia/Sydney", country: "Australia"),
        .init(name: "Taipei", zone: "Asia/Taipei", country: ""),
        .init(name: "Tallinn", zone: "Europe/Tallinn", country: "Estonia"),
        .init(name: "Tashkent", zone: "Asia/Tashkent", country: "Uzbekistan"),
        .init(name: "Tegucigalpa", zone: "America/Tegucigalpa", country: "Honduras"),
        .init(name: "Tehran", zone: "Asia/Tehran", country: "Iran"),
        .init(name: "Ho Chi Minh City", zone: "Asia/Saigon", country: "Vietnam"),
        .init(name: "Tientsin", zone: "Asia/Shanghai", country: "China"),
        .init(name: "Tokyo", zone: "Asia/Tokyo", country: "Japan"),
        .init(name: "Toronto", zone: "Canada/Eastern", country: "Canada"),
        .init(name: "Tréhet", zone: "Europe/Paris", country: "France"),
        .init(name: "Tripoli", zone: "Africa/Tripoli", country: "Libya"),
        .init(name: "Tunis", zone: "Africa/Tunis", country: "Tunisia"),
        .init(name: "Turin", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Ulaanbaatar", zone: "Asia/Ulaanbaatar", country: "Mongolia"),
        .init(name: "UTC", zone: "UTC", country: "UTC"),
        .init(name: "Vaduz", zone: "Europe/Vaduz", country: "Liechtenstein"),
        .init(name: "Vallejo", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Valletta", zone: "Europe/Malta", country: "Malta"),
        .init(name: "Vancouver", zone: "America/Vancouver", country: "Canada"),
        .init(name: "Verona", zone: "Europe/Rome", country: "Italy"),
        .init(name: "Victoria", zone: "Indian/Mahe", country: "Seychelles"),
        .init(name: "Vienna", zone: "Europe/Vienna", country: "Austria"),
        .init(name: "Vilnius", zone: "Europe/Vilnius", country: "Lithuania"),
        .init(name: "Vladivostok", zone: "Asia/Vladivostok", country: "Russia"),
        .init(name: "Volgograd", zone: "Europe/Moscow", country: "Russia"),
        .init(name: "Walnut Creek", zone: "US/Pacific", country: "U.S.A."),
        .init(name: "Warsaw", zone: "Europe/Warsaw", country: "Poland"),
        .init(name: "Washington, D.C.", zone: "US/Eastern", country: "U.S.A."),
        .init(name: "Wellington", zone: "Pacific/Auckland", country: "New Zealand"),
        .init(name: "Winnipeg", zone: "America/Winnipeg", country: "Canada"),
        .init(name: "Yakutsk", zone: "Asia/Yakutsk", country: "Russia"),
        .init(name: "Yamoussoukro", zone: "Africa/Abidjan", country: "Ivory Coast"),
        .init(name: "Yaounde", zone: "Africa/Douala", country: "Cameroon"),
        .init(name: "Yekaterinburg", zone: "Asia/Yekaterinburg", country: "Russia"),
        .init(name: "Yerevan", zone: "Asia/Yerevan", country: "Armenia"),
        .init(name: "Zagreb", zone: "Europe/Zagreb", country: "Croatia"),
        .init(name: "Zurich", zone: "Europe/Zurich", country: "Switzerland")
    ]
}

struct RetroClockAlarm: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var hour: Int = 7
    var minute: Int = 0
    var weekdays: [Int] = []
    var label: String = "Alarm"
    var sound: String = "Marimba"
    var snooze: Bool = true
    var enabled: Bool = true
    var fireDate: Date?
    var lastFiredAt: Date?

    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        let days: [Int?] = weekdays.isEmpty ? [nil] : weekdays.map(Optional.some)
        return days.compactMap { day in
            calendar.nextDate(after: date, matching: DateComponents(hour: hour, minute: minute, second: 0, weekday: day), matchingPolicy: .nextTime, repeatedTimePolicy: .first)
        }.min()
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = RetroClockFormatting.uses24HourClock ? "H:mm" : "h:mm"
        let cal = Calendar.current
        let date = cal.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: minute)) ?? Date()
        return formatter.string(from: date)
    }

    var meridian: String { RetroClockFormatting.uses24HourClock ? "" : (hour >= 12 ? "PM" : "AM") }

    var details: String { label.isEmpty ? "Alarm" : label }

    var repeatingDetail: String { repeatDescription == "Never" ? "" : repeatDescription }

    var repeatDescription: String {
        let summary: String
        if weekdays.isEmpty { summary = "Never" }
        else if weekdays.count == 7 { summary = "Every day" }
        else if Set(weekdays) == Set([2,3,4,5,6]) { summary = "Weekdays" }
        else if Set(weekdays) == Set([1,7]) { summary = "Weekends" }
        else {
            let weekdaysNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            summary = weekdays.sorted().map { weekdaysNames[max(1, min($0, 7))] }.joined(separator: " ")
        }
        return summary
    }
}

final class RetroClockStore: ObservableObject {
    static let shared = RetroClockStore()
    @Published var cities: [RetroClockCity] = []
    @Published var alarms: [RetroClockAlarm] = []
    @Published var stopwatchAccumulated: TimeInterval = 0
    @Published var stopwatchStartedAt: Date?
    @Published var laps: [TimeInterval] = []
    @Published var timerDuration: TimeInterval = 300
    @Published var timerRemaining: TimeInterval = 300
    @Published var timerDeadline: Date?
    @Published var timerSound = "Marimba"
    @Published var timerFinished = false
    @Published var timerPaused = false
    @Published var soundingAlarm: RetroClockAlarm?
    @Published var notificationError: String?
    private let defaults: UserDefaults
    private let notificationsEnabled: Bool
    private let alarmsKey = "oldos.clock.alarms.v1"
    private let citiesKey = "oldos.clock.cities.v1"
    private let timerKey = "oldos.clock.timer.v1"
    private let stopwatchKey = "oldos.clock.stopwatch.v1"
    private let timerNotificationID = "oldos.clock.timer"
    private var snoozes: [String: Date] = [:]
    private var lastAlarmCheck: Date
    private var alarmScheduleRevision = UUID()
    private var timerScheduleRevision = UUID()
    private var subscriptions = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard, startService: Bool = true, now: Date = Date()) {
        self.defaults = defaults
        notificationsEnabled = startService
        lastAlarmCheck = now
        func decode<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
            defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
        }
        cities = decode([RetroClockCity].self, citiesKey) ?? [.init(name: "Cupertino", zone: "America/Los_Angeles")]
        alarms = decode([RetroClockAlarm].self, alarmsKey) ?? []
        snoozes = decode([String: Date].self, "oldos.clock.snoozes.v1") ?? [:]
        if let value = decode(RetroClockStopwatchSnapshot.self, stopwatchKey) {
            stopwatchAccumulated = value.accumulated; stopwatchStartedAt = value.startedAt; laps = value.laps
        }
        if let value = decode(RetroClockTimerSnapshot.self, timerKey) {
            timerDuration = value.duration; timerRemaining = value.remaining; timerDeadline = value.deadline; timerSound = value.sound
            timerFinished = value.finished ?? (value.deadline == nil && value.remaining == 0 && value.duration > 0)
            timerPaused = value.paused ?? (value.deadline == nil && value.remaining > 0 && value.remaining != value.duration)
        }
        prepareOneShotDates(after: now)
        sortAlarms()
        if startService {
            // The service belongs to the app, not the Clock screen's lifetime.
            Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] in self?.tick($0) }.store(in: &subscriptions)
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] _ in
                self?.tick(Date()); self?.synchronizeAlarms()
            }.store(in: &subscriptions)
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).sink { _ in
                RetroClockAudio.stopPreview(); RetroClockAudio.stopRinging()
            }.store(in: &subscriptions)
            tick(now)
        }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
    func saveCities() { persist(cities, key: citiesKey) }
    func sortAlarms() { alarms.sort { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) } }
    private func prepareOneShotDates(after date: Date) {
        for index in alarms.indices where alarms[index].enabled && alarms[index].weekdays.isEmpty && alarms[index].fireDate == nil {
            alarms[index].fireDate = alarms[index].nextOccurrence(after: date)
        }
        persist(alarms, key: alarmsKey)
    }
    func saveAlarms() {
        prepareOneShotDates(after: Date()); sortAlarms(); persist(alarms, key: alarmsKey)
        let validIDs = Set(alarms.map { $0.id.uuidString })
        for id in snoozes.keys where !validIDs.contains(id) {
            snoozes[id] = nil
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["oldos.clock.snoozed." + id])
        }
        persist(snoozes, key: "oldos.clock.snoozes.v1")
        synchronizeAlarms()
    }
    func setAlarm(_ id: UUID, enabled: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].enabled = enabled
        alarms[index].fireDate = nil
        if !enabled {
            snoozes[id.uuidString] = nil
            if notificationsEnabled { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["oldos.clock.snoozed." + id.uuidString]) }
        }
        saveAlarms()
    }
    func deleteAlarm(_ id: UUID) {
        alarms.removeAll { $0.id == id }
        if soundingAlarm?.id == id { dismissAlarm() }
        saveAlarms()
    }
    func saveStopwatch() { persist(RetroClockStopwatchSnapshot(accumulated: stopwatchAccumulated, startedAt: stopwatchStartedAt, laps: laps), key: stopwatchKey) }
    func saveTimer() { persist(RetroClockTimerSnapshot(duration: timerDuration, remaining: timerRemaining, deadline: timerDeadline, sound: timerSound, paused: timerPaused, finished: timerFinished), key: timerKey) }
    func addCity(_ city: RetroClockCity) {
        guard !cities.contains(where: { $0.name == city.name }) else { return }
        cities.append(city); saveCities()
    }
    func removeCity(_ city: RetroClockCity) { cities.removeAll { $0.id == city.id }; saveCities() }
    func moveCity(_ index: Int, by offset: Int) {
        let destination = index + offset
        guard cities.indices.contains(index), cities.indices.contains(destination) else { return }
        cities.insert(cities.remove(at: index), at: destination); saveCities()
    }
    func elapsed(at now: Date) -> TimeInterval { stopwatchAccumulated + (stopwatchStartedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0) }
    func toggleStopwatch(at now: Date) {
        if let start = stopwatchStartedAt { stopwatchAccumulated += max(0, now.timeIntervalSince(start)); stopwatchStartedAt = nil }
        else { stopwatchStartedAt = now }
        saveStopwatch()
    }
    func recordLap(at now: Date) {
        guard stopwatchStartedAt != nil else { return }
        laps.insert(max(0, elapsed(at: now) - laps.reduce(0, +)), at: 0); saveStopwatch()
    }
    func resetStopwatch() { guard stopwatchStartedAt == nil else { return }; stopwatchAccumulated = 0; laps = []; saveStopwatch() }
    func remaining(at now: Date) -> TimeInterval { timerDeadline.map { max(0, $0.timeIntervalSince(now)) } ?? max(0, timerRemaining) }
    func configureTimer(hours: Int, minutes: Int) {
        guard timerDeadline == nil else { return }
        timerDuration = TimeInterval(hours * 3600 + minutes * 60); timerRemaining = timerDuration; saveTimer()
    }
    func startTimer(at now: Date) {
        guard timerDeadline == nil, timerRemaining > 0 else { return }
        timerFinished = false; timerPaused = false; timerDeadline = now.addingTimeInterval(timerRemaining); saveTimer(); scheduleTimerNotification()
    }
    func updateTimerSound(_ sound: String, at now: Date) {
        timerSound = sound; saveTimer()
        if timerDeadline != nil { scheduleTimerNotification() }
    }
    private func scheduleTimerNotification() {
        guard notificationsEnabled else { return }
        timerScheduleRevision = UUID()
        let revision = timerScheduleRevision
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [timerNotificationID])
        requestNotifications { [weak self] in
            guard let self, self.timerScheduleRevision == revision, let deadline = self.timerDeadline, deadline > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = "Timer"; content.body = "Timer Done"; content.categoryIdentifier = "oldos.clock.timer"
            content.sound = RetroClockAudio.notificationSound(self.timerSound)
            content.userInfo = ["clockKind": "timer"]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
            self.addNotification(UNNotificationRequest(identifier: self.timerNotificationID, content: content, trigger: trigger))
        }
    }
    func pauseTimer(at now: Date) {
        timerRemaining = remaining(at: now); timerDeadline = nil; timerPaused = true; timerScheduleRevision = UUID()
        if notificationsEnabled { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationID]) }; saveTimer()
    }
    func cancelTimer() {
        timerDeadline = nil; timerRemaining = timerDuration; timerFinished = false; timerPaused = false; timerScheduleRevision = UUID()
        RetroClockAudio.stopRinging(key: "timer")
        if notificationsEnabled { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationID]) }; saveTimer()
    }
    private func finishTimer(playSound: Bool) {
        guard !timerFinished else { return }
        timerDeadline = nil; timerRemaining = 0; timerFinished = true; timerPaused = false; saveTimer()
        if timerSound == "Sleep iPod" { MPMusicPlayerController.systemMusicPlayer.pause() }
        else if playSound { RetroClockAudio.ring(timerSound, key: "timer") }
    }
    func tick(_ now: Date) {
        let active = UIApplication.shared.applicationState == .active
        if let deadline = timerDeadline, now >= deadline { finishTimer(playSound: active && now.timeIntervalSince(deadline) < 60) }
        for alarm in alarms where alarm.enabled {
            let due = alarm.weekdays.isEmpty ? alarm.fireDate : alarm.nextOccurrence(after: lastAlarmCheck)
            if let due, due <= now { consumeAlarm(alarm, at: due, present: active && now.timeIntervalSince(due) < 60) }
        }
        var consumedSnooze = false
        for (id, deadline) in snoozes where deadline <= now {
            consumedSnooze = true
            snoozes[id] = nil
            if let alarm = alarms.first(where: { $0.id.uuidString == id }), active && now.timeIntervalSince(deadline) < 60 {
                soundingAlarm = alarm; RetroClockAudio.ring(alarm.sound, key: id)
            }
        }
        if consumedSnooze { persist(snoozes, key: "oldos.clock.snoozes.v1") }
        lastAlarmCheck = now
    }
    private func consumeAlarm(_ alarm: RetroClockAlarm, at date: Date, present: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        if let last = alarms[index].lastFiredAt, abs(last.timeIntervalSince(date)) < 1 { return }
        alarms[index].lastFiredAt = date
        if alarm.weekdays.isEmpty { alarms[index].enabled = false }
        persist(alarms, key: alarmsKey)
        if present { soundingAlarm = alarm; RetroClockAudio.ring(alarm.sound, key: alarm.id.uuidString) }
    }
    func receive(_ request: UNNotificationRequest, opened: Bool = false) {
        let info = request.content.userInfo
        if request.identifier == timerNotificationID { finishTimer(playSound: true); return }
        guard let id = info["clockAlarmID"] as? String,
              let alarm = alarms.first(where: { $0.id.uuidString == id }) else { return }
        if request.identifier.hasPrefix("oldos.clock.snoozed.") {
            // The tick and notification may race. Consuming the persisted deadline
            // once prevents a late notification from restarting a dismissed alert.
            guard let deadline = snoozes.removeValue(forKey: id) ?? (opened ? (info["clockFireDate"] as? Double).map(Date.init(timeIntervalSince1970:)) : nil) else { return }
            persist(snoozes, key: "oldos.clock.snoozes.v1")
            if Date().timeIntervalSince(deadline) < 60 { soundingAlarm = alarm; RetroClockAudio.ring(alarm.sound, key: id) }
        } else {
            let due = (info["clockFireDate"] as? Double).map(Date.init(timeIntervalSince1970:)) ?? Date().addingTimeInterval(-Double(Calendar.current.component(.second, from: Date())))
            consumeAlarm(alarm, at: due, present: true)
            if opened && soundingAlarm == nil && Date().timeIntervalSince(due) < 60 {
                soundingAlarm = alarm; RetroClockAudio.ring(alarm.sound, key: id)
            }
        }
    }
    func dismissNotification(_ request: UNNotificationRequest) {
        if request.identifier == timerNotificationID { cancelTimer(); return }
        guard let id = request.content.userInfo["clockAlarmID"] as? String,
              let alarm = alarms.first(where: { $0.id.uuidString == id }) else { return }
        if alarm.weekdays.isEmpty, let due = alarm.fireDate { consumeAlarm(alarm, at: due, present: false) }
        snoozes[id] = nil; persist(snoozes, key: "oldos.clock.snoozes.v1")
        if soundingAlarm?.id == alarm.id { dismissAlarm() }
    }
    func dismissAlarm() {
        if let alarm = soundingAlarm { RetroClockAudio.stopRinging(key: alarm.id.uuidString) }
        soundingAlarm = nil
    }
    func snoozeAlarm(_ alarm: RetroClockAlarm, at now: Date = Date()) {
        let due = alarm.weekdays.isEmpty ? alarm.fireDate : alarm.nextOccurrence(after: lastAlarmCheck)
        if let due, due <= now { consumeAlarm(alarm, at: due, present: false) }
        dismissAlarm()
        let deadline = now.addingTimeInterval(9 * 60)
        snoozes[alarm.id.uuidString] = deadline; persist(snoozes, key: "oldos.clock.snoozes.v1")
        requestNotifications {
            guard self.snoozes[alarm.id.uuidString] == deadline, self.alarms.contains(where: { $0.id == alarm.id }) else { return }
            let content = self.notificationContent(for: alarm)
            content.userInfo["clockFireDate"] = deadline.timeIntervalSince1970
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
            self.addNotification(UNNotificationRequest(identifier: "oldos.clock.snoozed." + alarm.id.uuidString, content: content, trigger: trigger))
        }
    }
    private func notificationContent(for alarm: RetroClockAlarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm" : alarm.label; content.body = "Alarm"
        content.sound = RetroClockAudio.notificationSound(alarm.sound)
        content.categoryIdentifier = alarm.snooze ? "oldos.clock.snoozable" : "oldos.clock.alarm"
        content.userInfo = ["clockAlarmID": alarm.id.uuidString]
        return content
    }
    func synchronizeAlarms() {
        guard notificationsEnabled else { return }
        alarmScheduleRevision = UUID()
        let revision = alarmScheduleRevision
        let notifications = UNUserNotificationCenter.current()
        notifications.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                guard let self, self.alarmScheduleRevision == revision else { return }
                notifications.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier).filter { $0.hasPrefix("oldos.clock.alarm.") })
                guard self.alarms.contains(where: \.enabled) else { return }
                self.requestNotifications {
                    guard self.alarmScheduleRevision == revision else { return }
                    for alarm in self.alarms where alarm.enabled {
                        if alarm.weekdays.isEmpty {
                            guard let date = alarm.fireDate, date > Date() else { continue }
                            let content = self.notificationContent(for: alarm)
                            content.userInfo["clockFireDate"] = date.timeIntervalSince1970
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
                            self.addNotification(UNNotificationRequest(identifier: "oldos.clock.alarm.\(alarm.id.uuidString).0", content: content, trigger: trigger))
                        } else {
                            for day in alarm.weekdays.sorted() {
                                let parts = DateComponents(hour: alarm.hour, minute: alarm.minute, weekday: day)
                                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
                                self.addNotification(UNNotificationRequest(identifier: "oldos.clock.alarm.\(alarm.id.uuidString).\(day)", content: self.notificationContent(for: alarm), trigger: trigger))
                            }
                        }
                    }
                }
            }
        }
    }
    private func addNotification(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error { DispatchQueue.main.async { self?.notificationError = error.localizedDescription } }
        }
    }
    private func requestNotifications(_ action: @escaping () -> Void) {
        guard notificationsEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted { action() }
                else { self?.notificationError = error?.localizedDescription ?? "Allow notifications in Settings to hear alarms and timers while OldOS is closed." }
            }
        }
    }
}

private struct RetroClockStopwatchSnapshot: Codable {
    let accumulated: TimeInterval
    let startedAt: Date?
    let laps: [TimeInterval]
}

private struct RetroClockTimerSnapshot: Codable {
    let duration: TimeInterval
    let remaining: TimeInterval
    let deadline: Date?
    let sound: String
    var paused: Bool? = nil
    var finished: Bool? = nil
}

private enum ClockRoute: Hashable {
    case main, citySearch, alarmEditor, alarmRepeat, alarmSound, alarmLabel, timerSound
}

struct Clock: View {
    @StateObject private var store = RetroClockStore.shared
    @State private var activeTab: RetroClockTab = .world
    @State private var routeStack: [ClockRoute] = []
    private var route: ClockRoute { routeStack.last ?? .main }
    @State private var now = Date()
    @State private var editingWorld = false
    @State private var editingAlarms = false
    @State private var pendingWorldDeletion: String?
    @State private var draggingCityId: String?
    @State private var worldDragY: CGFloat = 0
    @State private var worldDragGrabY: CGFloat = 46
    @State private var worldScrollOffset: CGFloat = 0
    @State private var pendingAlarmDeletion: UUID?
    @State private var citySearch = ""
    @State private var draft = RetroClockAlarm()
    @State private var isNewAlarm = true
    @State private var timerHours = 0
    @State private var timerMinutes = 5
    @State private var proposedTimerSound = "Marimba"
    private let clockPulse = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        clockCanvas.background(Color.black)
    }

    private var clockCanvas: some View {
        VStack(spacing: 0) {
            status_bar_in_app().frame(height: 24).zIndex(10)
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        if activeTab == .world || activeTab == .alarm {
                            header(for: .main).frame(height: 60)
                        }
                        GeometryReader { content in
                            scaledClockContent(height: content.size.height, width: content.size.width, destination: .main)
                        }
                        tabBar.frame(height: 57)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(0)
                    ForEach(Array(routeStack.enumerated()), id: \.offset) { layer in
                        VStack(spacing: 0) {
                            header(for: layer.element).frame(height: 60)
                            GeometryReader { content in
                                scaledClockContent(height: content.size.height, width: content.size.width, destination: layer.element)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color.black)
                        .clipped()
                        .transition(.move(edge: layer.element == .alarmEditor || layer.element == .citySearch || layer.element == .timerSound ? .bottom : .trailing))
                        .zIndex(Double(layer.offset + 1))
                    }
                }
                .clipped()
            }
        }
        .background(Color.black)
        .onReceive(clockPulse) { instant in
            if activeTab == .stopwatch && store.stopwatchStartedAt != nil ||
                activeTab == .timer && store.timerDeadline != nil ||
                (!editingWorld && !editingAlarms && Int(instant.timeIntervalSince1970) != Int(now.timeIntervalSince1970)) {
                now = instant
            }
            store.tick(instant)
        }
        .onAppear {
            store.synchronizeAlarms()
            store.tick(Date())
            let whole = Int(store.timerDuration)
            timerHours = whole / 3600
            timerMinutes = (whole % 3600) / 60
        }
        .onDisappear { finishWorldDrag(); RetroClockAudio.stopPreview(); RetroClockAudio.stopPickerTicks() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in finishWorldDrag() }
    }

    private func scaledClockContent(height: CGFloat, width: CGFloat, destination: ClockRoute) -> some View {
        let scale = max(0.1, width / 320)
        return Group {
            switch destination {
            case .main:
                switch activeTab {
                case .world: worldView
                case .alarm: alarmView
                case .stopwatch: stopwatchView
                case .timer: timerView
                }
            case .citySearch: citySearchView
            case .alarmEditor: alarmEditorView
            case .alarmRepeat: alarmRepeatView
            case .alarmSound: soundList(isTimer: false)
            case .alarmLabel: alarmLabelView
            case .timerSound: soundList(isTimer: true)
            }
        }
        .frame(width: 320, height: height / scale, alignment: .top)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: width, height: height, alignment: .topLeading)
        .clipped()
    }

    private func title(for destination: ClockRoute) -> String {
        switch destination {
        case .main: return activeTab.title
        case .citySearch: return "Choose a City"
        case .alarmEditor: return isNewAlarm ? "Add Alarm" : "Edit Alarm"
        case .alarmRepeat: return "Repeat"
        case .alarmSound: return "Sound"
        case .alarmLabel: return "Label"
        case .timerSound: return "When Timer Ends"
        }
    }

    private func navigate(_ destination: ClockRoute, back: Bool = false) {
        if destination == .timerSound && !back { proposedTimerSound = store.timerSound }
        if route == .alarmSound || route == .timerSound { RetroClockAudio.stopPreview() }
        if back {
            withAnimation(.easeInOut(duration: 0.30)) {
                if destination == .main {
                    routeStack.removeAll()
                } else if let existingIndex = routeStack.lastIndex(of: destination) {
                    routeStack = Array(routeStack.prefix(existingIndex + 1))
                }
            }
        } else if route != destination {
            withAnimation(.easeInOut(duration: 0.30)) {
                routeStack.append(destination)
            }
        }
    }

    private func header(for displayedRoute: ClockRoute) -> some View {
        ZStack {
            generic_title_bar(title: title(for: displayedRoute), show_done: false)
            HStack(spacing: 0) {
                switch displayedRoute {
                case .main:
                    if activeTab == .world {
                        tool_bar_rectangle_button(action: {
                            finishWorldDrag()
                            editingWorld.toggle()
                            pendingWorldDeletion = nil
                        }, button_type: .blue_gray, content: editingWorld ? "Done" : "Edit")
                    } else if activeTab == .alarm {
                        tool_bar_rectangle_button(action: {
                            editingAlarms.toggle()
                            pendingAlarmDeletion = nil
                        }, button_type: .blue_gray, content: editingAlarms ? "Done" : "Edit")
                    }
                case .citySearch, .alarmEditor:
                    tool_bar_rectangle_button(action: { navigate(.main, back: true) }, button_type: .blue_gray, content: "Cancel")
                case .alarmRepeat, .alarmSound, .alarmLabel:
                    tool_bar_rectangle_button(action: { navigate(.alarmEditor, back: true) }, button_type: .blue_gray, content: "Back")
                case .timerSound:
                    tool_bar_rectangle_button(action: { navigate(.main, back: true) }, button_type: .blue_gray, content: "Cancel")
                }
                Spacer(minLength: 0)
                switch displayedRoute {
                case .main:
                    if activeTab == .world {
                        tool_bar_rectangle_button(action: { citySearch = ""; navigate(.citySearch) }, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true)
                    } else if activeTab == .alarm {
                        tool_bar_rectangle_button(action: {
                            isNewAlarm = true
                            let time = Calendar.current.dateComponents([.hour, .minute], from: Date())
                            draft = RetroClockAlarm()
                            draft.hour = time.hour ?? 7
                            draft.minute = time.minute ?? 0
                            navigate(.alarmEditor)
                        }, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true)
                    }
                case .alarmEditor:
                    tool_bar_rectangle_button(action: { saveAlarm() }, button_type: .blue, content: "Save")
                case .timerSound:
                    tool_bar_rectangle_button(action: {
                        store.updateTimerSound(proposedTimerSound, at: Date())
                        navigate(.main, back: true)
                    }, button_type: .blue, content: "Set")
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 5)
        }
    }

    private var tabBar: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(LinearGradient(gradient: Gradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02),
                    .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04),
                    .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5),
                    .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51),
                    .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)
                ]), startPoint: .top, endPoint: .bottom))
                HStack(spacing: 0) {
                    ForEach(RetroClockTab.allCases, id: \.rawValue) { tab in
                        TabButton_Phone(
                            image: tab.title,
                            selectedTab: Binding(get: { activeTab.title }, set: { selected in
                                guard let next = RetroClockTab.allCases.first(where: { $0.title == selected }) else { return }
                                finishWorldDrag()
                                activeTab = next
                                editingWorld = false
                                editingAlarms = false
                                pendingWorldDeletion = nil
                                pendingAlarmDeletion = nil
                            }),
                            geometry: geometry,
                            assetName: tab.symbol,
                            tabCount: 4
                        )
                        .frame(width: geometry.size.width / 4, height: 55)
                    }
                }
                .frame(height: 55)
            }
            .frame(height: 57)
        }
    }

    private var worldView: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ClockOriginalStripeStage(showMap: true, height: geo.size.height)
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(store.cities.enumerated()), id: \.element.id) { index, city in
                                worldRow(city, viewportHeight: geo.size.height)
                                    .background(Image("clock-worldclock_row").resizable())
                                    .shadow(color: draggingCityId == city.id ? .black.opacity(0.45) : .clear, radius: 4, y: 3)
                                    .offset(y: draggingCityId == city.id ? ClockWorldDragLayout.top(pointerY: worldDragY, scrollOffset: worldScrollOffset, grabY: worldDragGrabY, count: store.cities.count, viewportHeight: geo.size.height) - CGFloat(index) * 92 : 0)
                                    .zIndex(draggingCityId == city.id ? 1 : 0)
                                    .id(city.id)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if !store.cities.isEmpty { ClockListBottomShadow().offset(y: 8) }
                        }
                        .background(GeometryReader { layout in
                            Color.clear.preference(key: ClockScrollOffset.self, value: -layout.frame(in: .named("ClockWorldViewport")).minY)
                        })
                    }
                    .clipped()
                    .coordinateSpace(name: "ClockWorldViewport")
                    .onPreferenceChange(ClockScrollOffset.self) { offset in
                        worldScrollOffset = offset
                        if draggingCityId != nil { updateWorldDrag(at: worldDragY, viewportHeight: geo.size.height) }
                    }
                    .onReceive(clockPulse) { _ in
                        guard let id = draggingCityId, let index = store.cities.firstIndex(where: { $0.id == id }),
                              worldDragY < 35 || worldDragY > geo.size.height - 35 else { return }
                        let next = min(max(0, index + (worldDragY < 35 ? -1 : 1)), store.cities.count - 1)
                        withAnimation(.linear(duration: 0.15)) { proxy.scrollTo(store.cities[next].id, anchor: worldDragY < 35 ? .top : .bottom) }
                    }
                }
                if store.cities.isEmpty {
                    Text("No World Clocks").font(.custom("HelveticaNeue-Bold", fixedSize: 20)).foregroundColor(.white.opacity(0.65))
                        .shadow(color: .black.opacity(0.6), radius: 0, y: -1).frame(height: geo.size.height)
                }
            }
        }
    }
    private func worldRow(_ city: RetroClockCity, viewportHeight: CGFloat) -> some View {
        ZStack {
            if editingWorld {
                HStack(spacing: 0) {
                    Button { finishWorldDrag(); withAnimation(.easeInOut(duration: 0.2)) { pendingWorldDeletion = pendingWorldDeletion == city.id ? nil : city.id } } label: {
                        Image("UIRemoveControlMinus").resizable().scaledToFit().frame(width: 24, height: 24)
                            .overlay(Capsule().fill(Color.white).frame(width: 11, height: 2))
                            .rotationEffect(.degrees(pendingWorldDeletion == city.id ? -90 : 0))
                    }.buttonStyle(ClockOpaqueButtonStyle()).frame(width: 32, height: 92).accessibilityLabel("Delete " + city.name)
                    Text(city.name).font(.custom("HelveticaNeue-Bold", fixedSize: 14)).foregroundColor(.black)
                        .lineLimit(1).minimumScaleFactor(0.85).padding(.leading, 8)
                    Spacer(minLength: 4)
                    RetroClockFace(zone: city.timeZone, date: now).frame(width: 77, height: 77)
                    if pendingWorldDeletion == city.id {
                        ClockNavigationButton(title: "Delete", destructive: true) { store.removeCity(city); pendingWorldDeletion = nil }
                            .padding(.horizontal, 8)
                    } else {
                        Image("UITableGrabber").resizable().scaledToFit().frame(width: 23, height: 18)
                            .frame(width: 39, height: 92).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .named("ClockWorldViewport"))
                                .onChanged { value in
                                    if draggingCityId == nil {
                                        draggingCityId = city.id; pendingWorldDeletion = nil
                                        let index = store.cities.firstIndex(where: { $0.id == city.id }) ?? 0
                                        worldDragGrabY = min(max(value.startLocation.y + worldScrollOffset - CGFloat(index) * 92, 0), 92)
                                    }
                                    updateWorldDrag(at: value.location.y, viewportHeight: viewportHeight)
                                }.onEnded { _ in finishWorldDrag() })
                            .accessibilityLabel("Reorder " + city.name)
                            .accessibilityAction(named: Text("Move up")) { if let i = store.cities.firstIndex(of: city) { store.moveCity(i, by: -1) } }
                            .accessibilityAction(named: Text("Move down")) { if let i = store.cities.firstIndex(of: city) { store.moveCity(i, by: 1) } }
                    }
                }.padding(.trailing, pendingWorldDeletion == city.id ? 0 : 4)
            } else {
                Text(city.name).font(.custom("HelveticaNeue-Bold", fixedSize: 14)).clockEngravedText(dark: true)
                    .lineLimit(1).minimumScaleFactor(0.85).frame(width: 110, alignment: .leading).position(x: 63, y: 46)
                RetroClockFace(zone: city.timeZone, date: now).frame(width: 77, height: 77).position(x: 159.5, y: 46.5)
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(RetroClockFormatting.digits(now, zone: city.timeZone)).font(.custom("HelveticaNeue-Bold", fixedSize: 18))
                        Text(RetroClockFormatting.period(now, zone: city.timeZone)).font(.custom("HelveticaNeue", fixedSize: 12))
                    }.foregroundColor(.black).lineLimit(1).minimumScaleFactor(0.8)
                    Text(RetroClockFormatting.dayDifference(now, zone: city.timeZone)).font(.custom("HelveticaNeue-Bold", fixedSize: 11)).foregroundColor(Color(white: 0.40)).shadow(color: .white.opacity(0.67), radius: 0, y: 0.7)
                }.frame(width: 108, alignment: .trailing).position(x: 258, y: 46)
            }
        }.frame(width: 320, height: 92)
    }
    private func updateWorldDrag(at y: CGFloat, viewportHeight: CGFloat) {
        worldDragY = y
        guard let id = draggingCityId, let current = store.cities.firstIndex(where: { $0.id == id }), !store.cities.isEmpty else { return }
        let top = ClockWorldDragLayout.top(pointerY: y, scrollOffset: worldScrollOffset, grabY: worldDragGrabY, count: store.cities.count, viewportHeight: viewportHeight)
        let destination = ClockWorldDragLayout.destination(top: top, count: store.cities.count)
        if current != destination { store.cities.insert(store.cities.remove(at: current), at: destination) }
    }
    private func finishWorldDrag() {
        if draggingCityId != nil { store.saveCities() }
        draggingCityId = nil
    }

    private var alarmView: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ClockOriginalStripeStage(height: geo.size.height)
                NoSepratorList {
                    ForEach(store.alarms) { alarm in
                        HStack(spacing: 0) {
                            if editingAlarms {
                                Button { withAnimation(.easeInOut(duration: 0.2)) { pendingAlarmDeletion = pendingAlarmDeletion == alarm.id ? nil : alarm.id } } label: {
                                    Image("UIRemoveControlMinus").resizable().scaledToFit().frame(width: 24, height: 24)
                            .overlay(Capsule().fill(Color.white).frame(width: 11, height: 2))
                                        .rotationEffect(.degrees(pendingAlarmDeletion == alarm.id ? -90 : 0))
                                }.buttonStyle(ClockOpaqueButtonStyle()).frame(width: 32, height: 92).accessibilityLabel("Delete alarm")
                            }
                            Button {
                                guard editingAlarms else { return }
                                draft = alarm; isNewAlarm = false; navigate(.alarmEditor)
                            } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text(alarm.formattedTime).font(.custom("HelveticaNeue-Bold", fixedSize: 23))
                                            .foregroundColor(alarm.enabled || editingAlarms ? .black : Color(white: 0.5))
                                        Text(alarm.meridian).font(.custom("HelveticaNeue", fixedSize: 12))
                                            .foregroundColor(alarm.enabled || editingAlarms ? .black : Color(white: 0.5))
                                    }
                                    if !alarm.repeatingDetail.isEmpty { Text(alarm.repeatingDetail).font(.custom("HelveticaNeue-Bold", fixedSize: 12))
                                        .foregroundColor(alarm.enabled || editingAlarms ? .black : Color(white: 0.5)).shadow(color: .white.opacity(0.65), radius: 0, y: 0.7).lineLimit(1) }
                                    Text(alarm.details).font(.custom("HelveticaNeue", fixedSize: 12))
                                        .foregroundColor(alarm.enabled || editingAlarms ? Color(red:95/255, green: 95/255, blue: 99/255) : Color(white: 0.5)).shadow(color: .white.opacity(0.67), radius: 0, y: 0.7).lineLimit(1)
                                }
                                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 92).contentShape(Rectangle())
                            }.buttonStyle(ClockOpaqueButtonStyle()).padding(.leading, editingAlarms ? 8 : 10)
                            if editingAlarms {
                                if pendingAlarmDeletion == alarm.id {
                                    ClockNavigationButton(title: "Delete", destructive: true) { store.deleteAlarm(alarm.id); pendingAlarmDeletion = nil }.padding(.trailing, 8)
                                } else {
                                    Image("UITableNext").resizable().scaledToFit().frame(width: 9, height: 14).padding(.horizontal, 12)
                                }
                            } else {
                                ClockIOS4Switch(on: alarm.enabled) { store.setAlarm(alarm.id, enabled: $0) }.padding(.trailing, 10)
                            }
                        }.frame(width: 320, height: 92).background(Image("clock-worldclock_row").resizable())
                            .overlay(alignment: .bottom) {
                                if alarm.id == store.alarms.last?.id { ClockListBottomShadow().offset(y: 8) }
                            }
                    }
                }
                if store.alarms.isEmpty {
                    Text("No Alarms").font(.custom("HelveticaNeue-Bold", fixedSize: 20)).foregroundColor(.white.opacity(0.65))
                        .shadow(color: .black.opacity(0.6), radius: 0, y: -1).frame(height: geo.size.height)
                }
            }
        }
    }

    private var stopwatchView: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Image("clock-topbackground_whole")
                        .resizable()
                        .frame(width: 320, height: 216)
                    Text(store.stopwatchStartedAt != nil || store.stopwatchAccumulated > 0 ? RetroClockFormatting.stopwatch(max(0, store.elapsed(at: now) - store.laps.reduce(0, +))) : "")
                        .font(.custom("Helvetica Neue Bold", fixedSize: 21))
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 0.6, x: 0, y: -1)
                        .frame(width: 293, height: 32, alignment: .trailing)
                        .position(x: 160, y: 31)
                    Text(RetroClockFormatting.stopwatch(store.elapsed(at: now)))
                        .font(.custom("Helvetica Neue Regular", fixedSize: 51))
                        .monospacedDigit()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.45), radius: 0.7, x: 0, y: -1)
                        .frame(width: 305, height: 70)
                        .position(x: 160, y: 96)
                    ClockOriginalInsetButton(title: store.stopwatchStartedAt == nil ? "Start" : "Stop",
                        color: store.stopwatchStartedAt == nil ? "green" : "red") {
                            store.toggleStopwatch(at: Date())
                        }
                        .frame(width: 125, height: 47)
                        .position(x: 86, y: 168.5)
                    ClockOriginalInsetButton(title: store.stopwatchStartedAt == nil ? "Reset" : "Lap",
                        color: "silver", disabled: store.stopwatchStartedAt == nil && store.stopwatchAccumulated == 0) {
                            if store.stopwatchStartedAt == nil { store.resetStopwatch() }
                            else { store.recordLap(at: Date()) }
                        }
                        .frame(width: 125, height: 47)
                        .position(x: 234, y: 168.5)
                }
                .frame(width: 320, height: 216)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.laps.enumerated()), id: \.offset) { index, lap in
                            ZStack(alignment: .leading) {
                                Text("lap \(store.laps.count - index)")
                                    .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                                    .foregroundColor(Color(red: 84/255, green: 85/255, blue: 89/255))
                                    .frame(width: 145).position(x: 85.5, y: 26.5)
                                Text(RetroClockFormatting.stopwatch(lap))
                                    .font(.custom("Helvetica Neue Bold", fixedSize: 21)).monospacedDigit()
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(width: 144, alignment: .leading).clipped()
                                    .position(x: 248, y: 26.5)
                            }
                            .foregroundColor(.black)
                            .shadow(color: .white.opacity(0.52), radius: 0, x: 0, y: 1)
                            .frame(width: 320, height: 53)
                            .background(Image("clock-stopwatch_lap_row_background").resizable(resizingMode: .stretch))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.82, green: 0.82, blue: 0.835))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var timerView: some View {
        GeometryReader { geo in
            let remaining = store.remaining(at: now)
            let running = store.timerDeadline != nil
            let paused = store.timerPaused
            ZStack(alignment: .topLeading) {
                Color(red: 25/255, green: 25/255, blue: 25/255)
                ZStack(alignment: .topLeading) {
                    Image(running || paused || store.timerFinished ? "clock-timer-running-body-seamless-v15" : "clock-timer-body-seamless-v15")
                        .resizable()
                        .frame(width: 320, height: 412)
                    if running || paused || store.timerFinished {
                        Text(RetroClockFormatting.countdown(remaining))
                            .font(.custom("Helvetica Neue Light", fixedSize: 49))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .frame(width: 300, height: 86)
                            .position(x: 160, y: 107)
                        Text(store.timerFinished ? "Timer Done" : paused ? "Paused" : "Time Remaining")
                            .font(.custom("Helvetica Neue Regular", fixedSize: 14))
                            .foregroundColor(.white.opacity(0.82))
                            .frame(width: 300, height: 25)
                            .position(x: 160, y: 165)
                    } else {
                        HStack(spacing: 3) {
                            OldOSClockWheel(value: $timerHours, range: 0..<24, suffix: "hours", rowHeight: 44)
                                .frame(width: 124.5, height: 196)
                                .overlay(alignment: .leading) {
                                    Text(timerHours == 1 ? "hour" : "hours")
                                        .font(.custom("Helvetica Neue Bold", fixedSize: 17.5))
                                        .foregroundColor(.black)
                                        .offset(x: 49)
                                        .allowsHitTesting(false)
                                }
                                .clipped()
                            OldOSClockWheel(value: $timerMinutes, range: 0..<60, suffix: "min", rowHeight: 44)
                                .frame(width: 124.5, height: 196)
                                .overlay(alignment: .leading) {
                                    Text(timerMinutes == 1 ? "min" : "mins")
                                        .font(.custom("Helvetica Neue Bold", fixedSize: 17.5))
                                        .foregroundColor(.black)
                                        .offset(x: 49)
                                        .allowsHitTesting(false)
                                }
                                .clipped()
                        }
                        .frame(width: 252, height: 196)
                        .compositingGroup()
                        .mask { RoundedRectangle(cornerRadius: 4).padding(.vertical, 2) }
                        .position(x: 160, y: 108)
                        .onChange(of: timerHours) { _ in store.configureTimer(hours: timerHours, minutes: timerMinutes) }
                        .onChange(of: timerMinutes) { _ in store.configureTimer(hours: timerHours, minutes: timerMinutes) }
                    }
                    Button {
                        navigate(.timerSound)
                    } label: {
                        HStack(spacing: 0) {
                            Text("When Timer Ends")
                                .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                                .foregroundColor(.black)
                                .shadow(color: Color.white.opacity(0.6), radius: 0, x: 0, y: 1)
                            Spacer()
                            Text(store.timerSound)
                                .font(.custom("Helvetica Neue Regular", fixedSize: 13))
                                .foregroundColor(Color(white: 0.32))
                                .shadow(color: .white.opacity(0.6), radius: 0, x: 0, y: 1)
                            Image("clock-timer_chevron")
                                .padding(.leading, 6)
                        }
                        .padding(.horizontal, 12)
                        .frame(width: 294, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ClockOpaqueButtonStyle())
                    .position(x: 160, y: 277)
                    if running || paused {
                        Image("clock-running-two-wells")
                            .resizable()
                            .frame(width: 320, height: 66)
                            .position(x: 160, y: 341)
                        ClockOriginalInsetButton(title: "Cancel", color: "red") {
                            store.cancelTimer()
                        }
                        .frame(width: 125, height: 47)
                        .position(x: 86, y: 341.5)
                        ClockOriginalInsetButton(title: paused ? "Resume" : "Pause", color: "silver") {
                            if paused { store.startTimer(at: Date()) }
                            else { store.pauseTimer(at: Date()) }
                        }
                        .frame(width: 125, height: 47)
                        .position(x: 234, y: 341.5)
                        .animationsDisabled()
                    } else {
                        ClockOriginalInsetButton(title: store.timerFinished ? "Reset" : "Start", color: "green",
                                                  disabled: !store.timerFinished && timerHours == 0 && timerMinutes == 0) {
                            if store.timerFinished { store.cancelTimer() }
                            else { store.startTimer(at: Date()) }
                        }
                        .frame(width: 292, height: 47)
                        .position(x: 159.5, y: 342.5)
                    }
                 }
                .frame(width: 320, height: 412)
            }
        }
    }

    private var citySearchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image("search_icon").resizable().frame(width: 14, height: 14).padding(.leading, 8)
                OldOSTextField("Search", text: $citySearch, configuration: .search,
                               font: UIFont(name: "HelveticaNeue", size: 17) ?? .systemFont(ofSize: 17),
                               height: 28, focusOnAppear: true)
                if !citySearch.isEmpty {
                    Button { citySearch = "" } label: { Image("UITextFieldClearButton") }.buttonStyle(ClockOpaqueButtonStyle()).padding(.trailing, 6)
                }
            }.frame(height: 28).background(Color.white).clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color(white: 0.65), lineWidth: 1)).padding(.horizontal, 6)
                .frame(height: 44).background(LinearGradient(colors: [Color(white: 0.94), Color(red: 0.69, green: 0.74, blue: 0.78)], startPoint: .top, endPoint: .bottom))
            NoSepratorList {
                if !citySearch.isEmpty && !RetroClockCity.choices.contains(where: { $0.searchName.localizedCaseInsensitiveContains(citySearch) }) {
                    Text("No Results Found")
                        .font(.custom("Helvetica Neue Bold", fixedSize: 15))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 22)
                }
                ForEach(RetroClockCity.choices.filter { citySearch.isEmpty || $0.searchName.localizedCaseInsensitiveContains(citySearch) }.sorted { $0.name < $1.name }) { city in
                    Button {
                        store.addCity(city)
                        navigate(.main, back: true)
                    } label: {
                        ClockTableRow(label: city.searchName)
                    }.buttonStyle(ClockOpaqueButtonStyle())
                }
            }
        }
        .background(Color.white)
    }

    private var alarmEditorView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                alarmSettings
                Spacer(minLength: 12)
                alarmTimeWheel
            }.frame(width: 320, height: geometry.size.height, alignment: .top)
                .background(Image("clock-stripe_background").resizable())
        }
    }

    private var alarmSettings: some View {
        VStack(spacing: 0) {
            Button { navigate(.alarmRepeat) } label: { ClockAlarmSetting(label: "Repeat", detail: draft.repeatDescription, chevron: true) }
            Color(white: 0.67).frame(height: 0).overlay(alignment: .top) { Color(white: 0.67).frame(height: 1) }
            Button { navigate(.alarmSound) } label: { ClockAlarmSetting(label: "Sound", detail: draft.sound, chevron: true) }
            Color(white: 0.67).frame(height: 0).overlay(alignment: .top) { Color(white: 0.67).frame(height: 1) }
            ClockAlarmSetting(label: "Snooze", detail: "", switchControl: AnyView(ClockIOS4Switch(on: draft.snooze) { draft.snooze = $0 }))
            Color(white: 0.67).frame(height: 0).overlay(alignment: .top) { Color(white: 0.67).frame(height: 1) }
            Button { navigate(.alarmLabel) } label: { ClockAlarmSetting(label: "Label", detail: draft.label, chevron: true) }
        }.buttonStyle(ClockOpaqueButtonStyle()).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(white: 0.67), lineWidth: 1))
            .padding(.horizontal, 10).padding(.top, 12)
    }

    private var alarmTimeWheel: some View {
        OldOSAlarmWheelGroup(hour: $draft.hour, minute: $draft.minute)
        .frame(width: 320, height: 216)
    }

    private var alarmLabelView: some View {
        VStack(spacing: 0) {
            HStack {
                OldOSTextField("Alarm", text: $draft.label, configuration: .standard,
                               font: UIFont(name: "HelveticaNeue", size: 17) ?? .systemFont(ofSize: 17),
                               height: 32, focusOnAppear: true)
                    .padding(.horizontal, 12)
            }
            .frame(height: 44)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(white: 0.67), lineWidth: 1))
            .padding(.horizontal, 10).padding(.top, 12)
            Spacer()
        }
        .background(Image("clock-stripe_background").resizable())
    }

    private var alarmRepeatView: some View {
        NoSepratorList {
                ForEach(1...7, id: \.self) { weekday in
                    Button {
                        if draft.weekdays.contains(weekday) { draft.weekdays.removeAll { $0 == weekday } }
                        else { draft.weekdays.append(weekday); draft.weekdays.sort() }
                    } label: {
                        ClockTableRow(label: "Every " + Calendar.current.weekdaySymbols[weekday - 1], selected: draft.weekdays.contains(weekday))
                    }
                    .buttonStyle(ClockOpaqueButtonStyle())
                }
        }.background(Image("clock-stripe_background").resizable())
    }

    private func soundList(isTimer: Bool) -> some View {
        NoSepratorList {
                ForEach(RetroClockAudio.soundNames + (isTimer ? ["Sleep iPod"] : []) + ["None"], id: \.self) { sound in
                    Button {
                        if isTimer { proposedTimerSound = sound }
                        else { draft.sound = sound }
                        RetroClockAudio.preview(sound)
                    } label: {
                        ClockTableRow(label: sound, selected: isTimer ? proposedTimerSound == sound : draft.sound == sound, soundStyle: true)
                    }
                    .buttonStyle(ClockOpaqueButtonStyle())
                }
        }.background(Image("clock-stripe_background").resizable())
    }

    private func saveAlarm() {
        draft.label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.label.isEmpty { draft.label = "Alarm" }
        draft.fireDate = nil
        draft.lastFiredAt = nil
        draft.enabled = true
        if let index = store.alarms.firstIndex(where: { $0.id == draft.id }) {
            store.alarms[index] = draft
        } else {
            store.alarms.append(draft)
        }
        store.saveAlarms()
        navigate(.main, back: true)
    }
}

private struct ClockNavigationButton: View {
    let title: String
    var destructive = false
    let action: () -> Void
    var body: some View {
        tool_bar_rectangle_button(action: action, button_type: destructive ? .red : .blue_gray, content: title)
    }
}

private struct ClockOpaqueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct ClockListBottomShadow: View {
    var body: some View {
        LinearGradient(colors: [.black.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 8).allowsHitTesting(false)
    }
}

// Drag geometry is constrained independently of the raw pointer, which still
// drives edge autoscrolling for lists taller than the visible viewport.
private enum ClockWorldDragLayout {
    static let rowHeight: CGFloat = 92
    static func top(pointerY: CGFloat, scrollOffset: CGFloat, grabY: CGFloat, count: Int, viewportHeight: CGFloat) -> CGFloat {
        let lastTop = max(0, CGFloat(count - 1) * rowHeight)
        let offset = max(0, scrollOffset)
        let lower = min(offset, lastTop)
        let upper = max(lower, min(lastTop, offset + max(0, viewportHeight - rowHeight)))
        return min(max(pointerY + offset - grabY, lower), upper)
    }
    static func destination(top: CGFloat, count: Int) -> Int {
        min(max(0, Int((top + rowHeight / 2) / rowHeight)), max(0, count - 1))
    }
}

private struct ClockScrollOffset: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct RetroClockAlertOverlay: View {
    @ObservedObject private var store = RetroClockStore.shared
    var body: some View {
        ZStack {
            if let alarm = store.soundingAlarm {
                Color.black.opacity(0.45).ignoresSafeArea()
                skeumorphic_alert(title: "Alarm", subtitle: alarm.label == "Alarm" ? "" : alarm.label,
                                  dismiss_action: store.dismissAlarm,
                                  secondary_title: alarm.snooze ? "Snooze" : nil,
                                  secondary_action: alarm.snooze ? { store.snoozeAlarm(alarm) } : nil)
            } else if store.timerFinished && store.timerSound != "Sleep iPod" {
                Color.black.opacity(0.45).ignoresSafeArea()
                skeumorphic_alert(title: "Timer Done", subtitle: "", dismiss_action: store.cancelTimer)
            } else if let message = store.notificationError {
                Color.black.opacity(0.45).ignoresSafeArea()
                skeumorphic_alert(title: "Notifications", subtitle: message, dismiss_action: { store.notificationError = nil })
            }
        }
    }
}

private struct ClockInkStyle: ViewModifier {
    let dark: Bool
    func body(content: Content) -> some View {
        if dark {
            content
                .foregroundColor(.black)
                .overlay {
                    content.foregroundColor(Color.white.opacity(0.11))
                        .offset(y: 0.42)
                        .mask(content)
                }
                .shadow(color: Color.white.opacity(0.70), radius: 0, x: 0, y: 0.65)
        } else {
            content
                .foregroundColor(.white)
                .overlay {
                    content.foregroundColor(Color.black.opacity(0.13))
                        .offset(y: -0.4)
                        .mask(content)
                }
                .shadow(color: Color.black.opacity(0.38), radius: 0.4, x: 0, y: -1)
        }
    }
}

private extension View {
    func clockEngravedText(dark: Bool) -> some View {
        modifier(ClockInkStyle(dark: dark))
    }
}

private struct ClockTableRow: View {
    let label: String
    var detail: String = ""
    var chevron: Bool = false
    var selected: Bool = false
    var groupedSetting: Bool = false
    var soundStyle: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Text(label).font(.custom(groupedSetting ? "Helvetica Neue Bold" : "Helvetica Neue Regular", fixedSize: 17))
                .clockEngravedText(dark: true)
            Spacer()
            if !detail.isEmpty {
                Text(detail).font(.custom("Helvetica Neue Regular", fixedSize: 16))
                    .foregroundColor(groupedSetting ? Color(red: 0.32, green: 0.40, blue: 0.53) : .gray)
                    .shadow(color: .white.opacity(0.68), radius: 0, x: 0, y: 1)
                    .lineLimit(1)
            }
            if chevron { Image(groupedSetting ? "UITableNext" : "clock-timer_chevron").resizable().scaledToFit().frame(width: 10, height: 14).padding(.leading, 5) }
            if selected { Image("UIPreferencesBlueCheck").resizable().scaledToFit().frame(width: 19, height: 19) }
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(white: 0.78)).frame(height: 0.5), alignment: .bottom)
        .contentShape(Rectangle())
    }
}

private struct ClockOriginalStripeStage: View {
    var showMap = false
    let height: CGFloat
    var body: some View {
        ZStack(alignment: .top) {
            Image("clock-stripe_background")
                .resizable(capInsets: EdgeInsets(top: 12, leading: 0, bottom: 34, trailing: 0), resizingMode: .stretch)
                .frame(width: 320, height: height)
            if showMap {
                Image("clock-map")
                    .resizable()
                    .frame(width: 321, height: 182)
                    .position(x: 160, y: max(182, height - 122))
            }
        }
        .frame(width: 320, height: height)
        .clipped()
        .allowsHitTesting(false)
    }
}

private struct ClockIOS4Switch: View {
    let on: Bool
    let onChanged: (Bool) -> Void
    var body: some View {
        toggle(on: on, onChanged: onChanged)
            .id(on)
            .scaleEffect(0.84, anchor: .center)
            .frame(width: 88, height: 26)
    }
}

private struct ClockOriginalInsetButton: View {
    let title: String
    let color: String
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Helvetica Neue Bold", fixedSize: 18))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.55),
                        radius: 0.3, x: 0, y: -1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(ClockOriginalButtonStyle(color: color))
        .contentShape(Rectangle())
        .opacity(disabled ? 0.75 : 1)
        .disabled(disabled)
    }
}

private struct ClockOriginalButtonStyle: ButtonStyle {
    let color: String
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Image("clock-button_\(color)\(configuration.isPressed ? "_pressed" : "")")
                    .resizable(capInsets: EdgeInsets(top: 12, leading: 9, bottom: 12, trailing: 9), resizingMode: .stretch)
            )
    }
}

private struct ClockAlarmSetting: View {
    let label: String
    let detail: String
    var chevron = false
    var switchControl: AnyView? = nil
    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom("Helvetica Neue Bold", fixedSize: 15))
                .clockEngravedText(dark: true)
            Spacer(minLength: 6)
            if let switchControl { switchControl }
            else {
                Text(detail)
                    .font(.custom("Helvetica Neue Regular", fixedSize: 15))
                    .foregroundColor(Color(red: 0.24, green: 0.35, blue: 0.55))
                    .shadow(color: .white.opacity(0.65), radius: 0, x: 0, y: 1)
                    .lineLimit(1)
                if chevron {
                    Image("UITableNext")
                        .resizable().scaledToFit()
                        .frame(width: 9, height: 14)
                        .padding(.leading, 1)
                }
            }
        }
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

private struct OldOSAlarmWheelGroup: View {
    // Keep the model in 0...23 in both locale formats; changing the period must
    // never overwrite the minute or lose noon/midnight at the 12-hour boundary.
    @Binding var hour: Int
    @Binding var minute: Int

    private var uses24HourClock: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "h a"
        return format.contains("H") || format.contains("k")
    }

    private var displayedHour: Binding<Int> {
        Binding(get: {
            uses24HourClock ? hour : (hour % 12 == 0 ? 12 : hour % 12)
        }, set: { value in
            hour = uses24HourClock ? value : (hour / 12) * 12 + value % 12
        })
    }

    private var period: Binding<Int> {
        Binding(get: { hour / 12 }, set: { hour = hour % 12 + $0 * 12 })
    }

    private var drumWidth: CGFloat { uses24HourClock ? 120 : 176 }

    var body: some View {
        ZStack {
            Image("clock-UIPickerViewBackground").resizable()
            HStack(spacing: 0) {
                ClockAlarmWheelComponent(value: displayedHour,
                                        range: uses24HourClock ? 0..<24 : 1..<13,
                                        suffix: "clockHour", width: 60)
                ClockAlarmWheelComponent(value: $minute, range: 0..<60,
                                        suffix: "clockMinute", width: uses24HourClock ? 60 : 48)
                if !uses24HourClock {
                    ClockAlarmWheelComponent(value: period, range: 0..<2,
                                            suffix: "period", width: 68)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .fixedSize()
            // These original frame slices provide the surround's colors and
            // its lower specular edge; a guessed gradient omits both details.
            HStack(spacing: 0) {
                Image("clock-UIPickerViewFrameLeft")
                    .resizable(capInsets: EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 14))
                    .frame(width: (320 - drumWidth) / 2 + 5)
                Image("clock-UIPickerViewFrameMiddle").resizable().frame(width: drumWidth - 10)
                Image("clock-UIPickerViewFrameRight")
                    .resizable(capInsets: EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 1))
                    .frame(width: (320 - drumWidth) / 2 + 5)
            }.frame(height: 216).allowsHitTesting(false)
        }
        .frame(width: 320, height: 216)
        .clipped()
    }
}

private struct ClockAlarmWheelComponent: View {
    @Binding var value: Int
    let range: Range<Int>
    let suffix: String
    let width: CGFloat

    var body: some View {
        ZStack {
            // Preserve the four-point bevels instead of stretching a flattened
            // three-column image. Each component has its own original drum.
            Image("clock-UIPickerViewWheelBackground")
                .resizable(capInsets: EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .frame(width: width, height: 216)
            Image("clock-UIPickerViewSelectionBar")
                .resizable(capInsets: EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                .frame(width: width, height: 44)
            OldOSClockWheel(value: $value, range: range, suffix: suffix, rowHeight: 44)
            Image("clock-UIPickerViewShadowsAboveWheel")
                .resizable()
                .frame(width: width, height: 216)
                .allowsHitTesting(false)
            // The lens includes its lower shadow: 44 points of glass + 18 below.
            Image("clock-UIPickerViewSelectionBarAboveWheel")
                .resizable()
                .frame(width: width, height: 62)
                .offset(y: 9)
                .allowsHitTesting(false)
        }
        .frame(width: width, height: 200)
        .clipped()
        .overlay(alignment: .trailing) {
            if suffix == "clockHour" || (suffix == "clockMinute" && width == 48) {
                Image("clock-UIPickerViewSelectionBarAboveDivider").resizable()
                    .frame(width: 1, height: 48).offset(y: 2).allowsHitTesting(false)
            }
        }
    }
}

private struct OldOSClockWheel: UIViewRepresentable {
    @Binding var value: Int
    let range: Range<Int>
    let suffix: String
    let rowHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ClockWheelScrollView {
        let wheel = ClockWheelScrollView()
        wheel.configure(range: range, suffix: suffix, rowHeight: rowHeight, value: value)
        wheel.delegate = context.coordinator
        switch suffix {
        case "hours": wheel.accessibilityLabel = "Timer hours"
        case "min": wheel.accessibilityLabel = "Timer minutes"
        case "clockHour": wheel.accessibilityLabel = "Alarm hour"
        case "clockMinute": wheel.accessibilityLabel = "Alarm minute"
        default: wheel.accessibilityLabel = "AM or PM"
        }
        wheel.onAccessibilityChange = { context.coordinator.owner.value = $0 }
        return wheel
    }

    func updateUIView(_ wheel: ClockWheelScrollView, context: Context) {
        context.coordinator.owner = self
        wheel.configure(range: range, suffix: suffix, rowHeight: rowHeight, value: value)
        if !wheel.isTracking && !wheel.isDecelerating && wheel.logicalValue != value {
            wheel.move(to: value, animated: false, recenter: true)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var owner: OldOSClockWheel
        init(_ owner: OldOSClockWheel) { self.owner = owner }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let wheel = scrollView as? ClockWheelScrollView else { return }
            wheel.refreshVisibleLabels()
            guard wheel.isTracking || wheel.isDecelerating else { return }
            let newValue = wheel.value(at: wheel.contentOffset.y)
            guard newValue != owner.value else { return }
            owner.value = newValue
            wheel.playSelectionTick()
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            guard let wheel = scrollView as? ClockWheelScrollView else { return }
            let row = wheel.rowHeight
            targetContentOffset.pointee.y = min(max(0, (targetContentOffset.pointee.y / row).rounded() * row), wheel.maximumOffset)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate, let wheel = scrollView as? ClockWheelScrollView { finish(wheel) }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if let wheel = scrollView as? ClockWheelScrollView { finish(wheel) }
        }

        private func finish(_ wheel: ClockWheelScrollView) {
            let value = wheel.value(at: wheel.contentOffset.y)
            wheel.move(to: value, animated: false, recenter: true)
            if owner.value != value {
                owner.value = value
                wheel.playSelectionTick()
            }
        }
    }
}

private final class ClockWheelScrollView: UIScrollView {
    var rowHeight: CGFloat = 35
    private var availableRange: Range<Int> = 0..<24
    private var suffix: String = "hours"
    private var labels: [UILabel] = []
    private var positioned = false
    private var lastWidth: CGFloat = 0
    private var lastHeight: CGFloat = 0
    private var selectedValue = 0
    var onAccessibilityChange: ((Int) -> Void)?
    private var itemsPerCycle: Int { max(availableRange.count, 1) }
    private var totalRows: Int { suffix == "period" ? 2 : itemsPerCycle * 7 }
    var logicalValue: Int { value(at: contentOffset.y) }
    var maximumOffset: CGFloat { CGFloat(max(totalRows - 1, 0)) * rowHeight }

    override init(frame: CGRect) {
        super.init(frame: frame)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .clear
        decelerationRate = .fast
        bounces = false
        clipsToBounds = true
        layer.masksToBounds = true
        contentInsetAdjustmentBehavior = .never
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(range: Range<Int>, suffix: String, rowHeight: CGFloat, value: Int) {
        if labels.isEmpty || availableRange != range || self.suffix != suffix || self.rowHeight != rowHeight {
            availableRange = range
            self.suffix = suffix
            self.rowHeight = rowHeight
            selectedValue = value
            positioned = false
            labels.forEach { $0.removeFromSuperview() }
            labels.removeAll()
            for index in 0..<totalRows {
                let item = availableRange.lowerBound + index % itemsPerCycle
                let label = UILabel()
                label.text = format(item)
                label.textAlignment = (suffix == "clockHour" || suffix == "hours" || suffix == "min") ? .right : .center
                let fontSize: CGFloat = (suffix == "clockHour" || suffix == "clockMinute" || suffix == "period") ? 19 : 18
                label.font = UIFont(name: "HelveticaNeue", size: fontSize) ?? .systemFont(ofSize: fontSize)
                label.textColor = .black
                label.backgroundColor = .clear
                label.isUserInteractionEnabled = false
                addSubview(label)
                labels.append(label)
            }
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width, height = bounds.height
        guard width > 1 && height > 1 && !labels.isEmpty else { return }
        if width != lastWidth || height != lastHeight || !positioned {
            lastWidth = width
            lastHeight = height
            let cap = max(0, (height - rowHeight) / 2)
            for (index, label) in labels.enumerated() {
                if suffix == "hours" || suffix == "min" {
                    label.frame = CGRect(x: 0, y: cap + CGFloat(index) * rowHeight, width: 44, height: rowHeight)
                } else if suffix == "clockHour" {
                    label.frame = CGRect(x: 0, y: cap + CGFloat(index) * rowHeight, width: width - 10, height: rowHeight)
                } else {
                    label.frame = CGRect(x: 0, y: cap + CGFloat(index) * rowHeight, width: width, height: rowHeight)
                }
            }
            contentSize = CGSize(width: width, height: CGFloat(totalRows) * rowHeight + cap * 2)
            if !positioned {
                let position = (suffix == "period" ? 0 : itemsPerCycle * 3) + (selectedValue - availableRange.lowerBound)
                positioned = true
                setContentOffset(CGPoint(x: 0, y: CGFloat(position) * rowHeight), animated: false)
            }
        }
        refreshVisibleLabels()
    }

    func value(at position: CGFloat) -> Int {
        let index = Int((position / max(rowHeight, 1)).rounded())
        return availableRange.lowerBound + ((index % itemsPerCycle) + itemsPerCycle) % itemsPerCycle
    }

    func move(to value: Int, animated: Bool, recenter: Bool = false) {
        selectedValue = value
        guard positioned else { return }
        let normalized = ((value - availableRange.lowerBound) % itemsPerCycle + itemsPerCycle) % itemsPerCycle
        let currentRow = Int((contentOffset.y / rowHeight).rounded())
        let targetRow: Int
        if suffix == "period" {
            targetRow = normalized
        } else if recenter {
            // Return to the middle copy after settling, so repeated flings can
            // keep crossing 59/00 and 12/1 without reaching the buffer's ends.
            targetRow = itemsPerCycle * 3 + normalized
        } else {
            let nearestCycle = Int((Double(currentRow - normalized) / Double(itemsPerCycle)).rounded())
            targetRow = min(max(0, nearestCycle * itemsPerCycle + normalized), totalRows - 1)
        }
        setContentOffset(CGPoint(x: 0, y: CGFloat(targetRow) * rowHeight), animated: animated)
        refreshVisibleLabels()
    }

    func refreshVisibleLabels() {
        guard bounds.height > 1 else { return }
        let visibleCenter = contentOffset.y + bounds.height / 2
        let near = Int((contentOffset.y / max(rowHeight, 1)).rounded())
        let first = max(0, min(labels.count - 1, near - 5))
        let last = min(labels.count - 1, max(0, near + 5))
        guard first <= last else { return }
        for i in first...last {
            let distance = abs(labels[i].center.y - visibleCenter) / rowHeight
            let item = availableRange.lowerBound + i % itemsPerCycle
            if suffix == "hours" || suffix == "min" {
                labels[i].text = suffix == "hours" ? String(item) : String(format: "%02d", item)
            } else {
                labels[i].text = format(item)
            }
            let isTimerWheel = suffix == "hours" || suffix == "min"
            let fontSize: CGFloat = suffix == "period" ? 20 : 24
            labels[i].font = UIFont(name: "HelveticaNeue-Bold", size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .bold)
            labels[i].textColor = .black
            labels[i].alpha = isTimerWheel ? (distance < 1.5 ? 1 : 0.72) : 1.0
            labels[i].transform = CGAffineTransform(scaleX: 1, y: distance < 1.5 ? 1 : 0.96)
        }
        accessibilityValue = format(logicalValue)
    }

    // Only user row changes call this; setup and recentering stay silent.
    func playSelectionTick() {
        RetroClockAudio.pickerTick()
    }

    override func accessibilityIncrement() { adjustAccessibility(by: 1) }
    override func accessibilityDecrement() { adjustAccessibility(by: -1) }

    private func adjustAccessibility(by step: Int) {
        let proposed = logicalValue + step
        let next = suffix == "period" ? min(max(proposed, 0), 1) :
            availableRange.lowerBound + ((proposed - availableRange.lowerBound) % itemsPerCycle + itemsPerCycle) % itemsPerCycle
        guard next != logicalValue else { return }
        move(to: next, animated: false, recenter: true)
        playSelectionTick()
        onAccessibilityChange?(next)
    }

    private func format(_ n: Int) -> String {
        switch suffix {
        case "clockHour": return String(n)
        case "clockMinute": return String(format: "%02d", n)
        case "period": return n == 0 ? "AM" : "PM"
        case "hours": return "\(n) hour\(n == 1 ? "" : "s")"
        case "min": return "\(n) min"
        default: return String(n)
        }
    }
}

private struct RetroClockFace: View {
    let zone: TimeZone
    let date: Date

    var body: some View {
        let components = Calendar(identifier: .gregorian).dateComponents(in: zone, from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let evening = hour < 6 || hour >= 18
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 77
            ZStack {
                Image(evening ? "clock-pmbase" : "clock-base").resizable()
                // Native sizes and offsets come from AnalogClockView's
                // initWithFrame: and HandView's PDF drawing transform in 4.3.
                hand(evening ? "clock-pmhour" : "clock-hour",
                     size: CGSize(width: 9, height: evening ? 22 : 19), offset: CGPoint(x: 0, y: -1),
                     angle: Double(hour % 12) * 30 + Double(minute) * 0.5)
                hand(evening ? "clock-pmmins" : "clock-mins",
                     size: CGSize(width: evening ? 14 : 11, height: 37), offset: CGPoint(x: 0.5, y: -6.5),
                     angle: Double(minute) * 6 + Double(second) * 0.1)
                hand("clock-secs", size: CGSize(width: 5, height: 39), offset: CGPoint(x: 0, y: -3.5),
                     angle: Double(second) * 6)
            }
            .frame(width: 77, height: 77)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }

    private func hand(_ asset: String, size: CGSize, offset: CGPoint, angle: Double) -> some View {
        Image(asset)
            .resizable()
            .frame(width: size.width, height: size.height)
            .offset(x: offset.x, y: -size.height / 2 - offset.y)
            .frame(width: 77, height: 77)
            .rotationEffect(.degrees(angle))
    }
}


final class RetroClockAudio: NSObject, AVAudioPlayerDelegate {
    private static let shared = RetroClockAudio()
    private static let audioQueue = DispatchQueue(label: "OldOS.Clock.Audio", qos: .userInitiated)
    private var previewCompletion: DispatchWorkItem?
    private var previewPlayer: AVAudioPlayer?
    private var ringingPlayer: AVAudioPlayer?
    private var ringingKey: String?
    private var pickerPlayer: AVAudioPlayer?
    private var pickerSessionInUse = false
    private var pickerRelease: DispatchWorkItem?
    private var lastPickerTick: CFTimeInterval = -1
    private var previousSession: (AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions)?
    static let soundNames = ["Marimba", "Alarm", "Ascending", "Bark", "Bell Tower", "Blues", "Boing", "Crickets", "Digital", "Doorbell", "Duck", "Harp", "Motorcycle", "Old Car Horn", "Old Phone", "Piano Riff", "Pinball", "Robot", "Sci-Fi", "Sonar", "Strum", "Timba", "Time Passing", "Trill", "Xylophone"]
    static let files: [String: String] = [
        "Marimba": "clock_marimba.caf", "Alarm": "clock_alarm.caf", "Digital": "clock_digital.caf",
        "Blues": "clock_blues.caf", "Crickets": "clock_crickets.caf", "Xylophone": "clock_xylophone.caf",
        "Ascending": "clock_original_ascending.caf", "Bark": "clock_original_bark.caf",
        "Bell Tower": "clock_original_bell_tower.caf", "Boing": "clock_original_boing.caf",
        "Doorbell": "clock_original_doorbell.caf", "Duck": "clock_original_duck.caf",
        "Harp": "clock_original_harp.caf", "Motorcycle": "clock_original_motorcycle.caf",
        "Old Car Horn": "clock_original_old_car_horn.caf", "Old Phone": "clock_original_old_phone.caf",
        "Piano Riff": "clock_original_piano_riff.caf", "Pinball": "clock_original_pinball.caf",
        "Robot": "clock_original_robot.caf", "Sci-Fi": "clock_original_sci_fi.caf",
        "Sonar": "clock_original_sonar.caf", "Strum": "clock_original_strum.caf",
        "Timba": "clock_original_timba.caf", "Time Passing": "clock_original_time_passing.caf", "Trill": "clock_original_trill.caf"
    ]
    static func resource(_ name: String, bundle: Bundle = .main) -> URL? {
        guard let filename = files[name] else { return nil }
        return bundle.url(forResource: filename, withExtension: nil)
    }
    static func notificationSound(_ name: String) -> UNNotificationSound? {
        guard name != "None", name != "Sleep iPod" else { return nil }
        guard let filename = files[name], resource(name) != nil else {
            NSLog("Clock sound resource missing: %@", name); return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: filename))
    }
    static func pickerTick() {
        let requestedAt = CACurrentMediaTime()
        audioQueue.async {
            guard CACurrentMediaTime() - requestedAt < 0.08 else { return }
            shared.playPickerTick()
        }
    }
    static func stopPickerTicks(completion: (() -> Void)? = nil) {
        audioQueue.async { shared.endPickerTicks(); completion?() }
    }

    private func playPickerTick() {
        guard ringingPlayer == nil, previewPlayer == nil else { return }
        let time = CACurrentMediaTime()
        guard time - lastPickerTick >= 0.04 else { return }
        guard let url = Bundle.main.url(forResource: "Tock", withExtension: "aiff") else {
            NSLog("Clock picker sound resource missing: Tock.aiff")
            return
        }
        lastPickerTick = time
        do {
            if !pickerSessionInUse {
                let session = AVAudioSession.sharedInstance()
                if previousSession == nil { previousSession = (session.category, session.mode, session.categoryOptions) }
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                pickerSessionInUse = true
            }
            if pickerPlayer == nil {
                pickerPlayer = try AVAudioPlayer(contentsOf: url)
                pickerPlayer?.volume = 1
                pickerPlayer?.prepareToPlay()
            }
            pickerRelease?.cancel()
            pickerPlayer?.currentTime = 0
            guard pickerPlayer?.play() == true else {
                pickerPlayer = nil
                endPickerTicks()
                return
            }
            let release = DispatchWorkItem { [weak self] in self?.endPickerTicks() }
            pickerRelease = release
            Self.audioQueue.asyncAfter(deadline: .now() + 0.2, execute: release)
        } catch {
            NSLog("Clock picker sound failed: %@", error.localizedDescription)
            endPickerTicks()
        }
    }

    private func endPickerTicks() {
        pickerRelease?.cancel()
        pickerRelease = nil
        pickerPlayer?.stop()
        pickerSessionInUse = false
        releaseSessionIfIdle()
    }

    static func preview(_ name: String) {
        audioQueue.async { shared.startPreview(name) }
    }
    private func startPreview(_ name: String) {
        endPickerTicks()
        stopPreviewPlayer()
        guard ringingPlayer == nil else { return }
        previewPlayer = player(name, looping: false)
        if let previewPlayer { schedulePreviewCompletion(previewPlayer) }
        releaseSessionIfIdle()
    }
    private func schedulePreviewCompletion(_ player: AVAudioPlayer) {
        previewCompletion?.cancel()
        let completion = DispatchWorkItem { [weak self, weak player] in
            guard let self, let player, self.previewPlayer === player else { return }
            if player.isPlaying { self.schedulePreviewCompletion(player) }
            else { self.previewPlayer = nil; self.previewCompletion = nil; self.releaseSessionIfIdle() }
        }
        previewCompletion = completion
        Self.audioQueue.asyncAfter(deadline: .now() + max(0.1, player.duration + 0.05), execute: completion)
    }
    static func stopPreview() { audioQueue.async { shared.stopPreviewPlayer() } }
    private func stopPreviewPlayer() {
        previewCompletion?.cancel(); previewCompletion = nil
        previewPlayer?.stop(); previewPlayer = nil
        releaseSessionIfIdle()
    }
    static func ring(_ name: String, key: String) {
        audioQueue.async {
            shared.endPickerTicks(); shared.stopPreviewPlayer(); shared.stopRingingPlayer()
            shared.ringingKey = key
            shared.ringingPlayer = shared.player(name, looping: true)
            shared.releaseSessionIfIdle()
        }
    }
    static func stopRinging(key: String? = nil) { audioQueue.async { shared.stopRingingPlayer(key: key) } }
    private func stopRingingPlayer(key: String? = nil) {
        if let key, ringingKey != key { return }
        ringingPlayer?.stop(); ringingPlayer = nil; ringingKey = nil
        releaseSessionIfIdle()
    }
    private func player(_ name: String, looping: Bool) -> AVAudioPlayer? {
        guard name != "None", name != "Sleep iPod" else { return nil }
        guard let url = Self.resource(name) else { NSLog("Clock sound resource missing: %@", name); return nil }
        do {
            let session = AVAudioSession.sharedInstance()
            if previousSession == nil { previousSession = (session.category, session.mode, session.categoryOptions) }
            // .ambient is silenced by the ring/silent switch. Clock playback uses
            // the playback category and releases it when the preview/alarm ends.
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self; player.volume = 1; player.numberOfLoops = looping ? -1 : 0
            guard player.prepareToPlay(), player.play() else { NSLog("Clock could not play %@", name); return nil }
            return player
        } catch { NSLog("Clock audio error for %@: %@", name, error.localizedDescription); return nil }
    }
    private func releaseSessionIfIdle() {
        guard previewPlayer == nil, ringingPlayer == nil, !pickerSessionInUse, let previous = previousSession else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        try? session.setCategory(previous.0, mode: previous.1, options: previous.2)
        previousSession = nil
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Self.audioQueue.async {
            if player === self.previewPlayer { self.previewCompletion?.cancel(); self.previewCompletion = nil; self.previewPlayer = nil }
            if player === self.ringingPlayer { self.ringingPlayer = nil; self.ringingKey = nil }
            self.releaseSessionIfIdle()
        }
    }
}

enum RetroClockFormatting {
    static var uses24HourClock: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "h a"
        return format.contains("H") || format.contains("k")
    }
    static func digits(_ date: Date, zone: TimeZone) -> String {
        let format = DateFormatter(); format.timeZone = zone; format.dateFormat = uses24HourClock ? "H:mm" : "h:mm"
        return format.string(from: date)
    }
    static func period(_ date: Date, zone: TimeZone) -> String {
        guard !uses24HourClock else { return "" }
        let format = DateFormatter(); format.timeZone = zone; format.dateFormat = "a"
        return format.string(from: date)
    }
    static func time(_ date: Date, zone: TimeZone) -> String {
        let format = DateFormatter()
        format.timeZone = zone
        format.dateFormat = uses24HourClock ? "H:mm" : "h:mm a"
        return format.string(from: date)
    }

    static func dayDifference(_ date: Date, zone: TimeZone) -> String {
        var target = Calendar(identifier: .gregorian)
        target.timeZone = zone
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let targetDay = target.ordinality(of: .day, in: .era, for: date) ?? 0
        let localDay = local.ordinality(of: .day, in: .era, for: date) ?? 0
        if targetDay == localDay { return "Today" }
        return targetDay > localDay ? "Tomorrow" : "Yesterday"
    }

    static func stopwatch(_ interval: TimeInterval) -> String {
        let tenths = Int(max(0, interval) * 10)
        if tenths >= 36000 { return String(format: "%d:%02d:%02d.%d", tenths / 36000, (tenths / 600) % 60, (tenths / 10) % 60, tenths % 10) }
        return String(format: "%02d:%02d.%d", tenths / 600, (tenths / 10) % 60, tenths % 10)
    }

    static func countdown(_ interval: TimeInterval) -> String {
        let seconds = Int(ceil(max(0, interval)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }
}

final class RetroClockNotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = RetroClockNotificationRouter()
    private override init() { super.init() }
    func configure() {
        let snooze = UNNotificationAction(identifier: "oldos.clock.snooze", title: "Snooze", options: [])
        let category = UNNotificationCategory(identifier: "oldos.clock.snoozable", actions: [snooze], intentIdentifiers: [], options: [.customDismissAction])
        let center = UNUserNotificationCenter.current()
        let alarmCategory = UNNotificationCategory(identifier: "oldos.clock.alarm", actions: [], intentIdentifiers: [], options: [.customDismissAction])
        let timerCategory = UNNotificationCategory(identifier: "oldos.clock.timer", actions: [], intentIdentifiers: [], options: [.customDismissAction])
        center.getNotificationCategories { existing in center.setNotificationCategories(existing.union([category, alarmCategory, timerCategory])) }
        center.delegate = self
        _ = RetroClockStore.shared
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier.hasPrefix("oldos.clock.") {
            DispatchQueue.main.async {
                RetroClockStore.shared.receive(notification.request)
                completionHandler([]) // The classic alert owns foreground audio; avoid a second sound/banner.
            }
        } else { completionHandler([.banner, .sound]) }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            let store = RetroClockStore.shared
            if response.actionIdentifier == UNNotificationDismissActionIdentifier {
                store.dismissNotification(response.notification.request)
            } else if response.actionIdentifier == "oldos.clock.snooze",
               let id = response.notification.request.content.userInfo["clockAlarmID"] as? String,
               let alarm = store.alarms.first(where: { $0.id.uuidString == id }) {
                store.snoozeAlarm(alarm)
            } else if response.notification.request.identifier.hasPrefix("oldos.clock.") {
                store.receive(response.notification.request, opened: true)
            }
            completionHandler()
        }
    }
}
