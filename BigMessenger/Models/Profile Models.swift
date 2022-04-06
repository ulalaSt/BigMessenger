//
//  Profile Models.swift
//  BigMessenger
//
//  Created by user on 03.04.2022.
//

import Foundation


enum ProfileViewModelType {
    case info, logout
}
struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (()->Void)?
}
