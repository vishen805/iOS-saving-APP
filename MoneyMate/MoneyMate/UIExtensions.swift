//
//  UIExtensions.swift
//  MoneyMate
//

import SwiftUI

extension View {
    @ViewBuilder
    func numericKeyboard() -> some View {
        #if canImport(UIKit)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

struct PlatformPageTabStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.tabViewStyle(.page)
        #else
        content
        #endif
    }
}


