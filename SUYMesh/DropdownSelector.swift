import SwiftUI

@available(iOS 13.0, *)
struct DropdownOption: Hashable {
    let key: String
    let value: String

    public static func == (lhs: DropdownOption, rhs: DropdownOption) -> Bool {
        return lhs.key == rhs.key
    }
}

@available(iOS 13.0, *)
struct DropdownRow: View {
    var option: DropdownOption
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?

    var body: some View {
        Button(action: {
            if let onOptionSelected = self.onOptionSelected {
                onOptionSelected(self.option)
            }
        }) {
            HStack {
                Text(self.option.value)
                    .font(.system(size: 14))
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}

@available(iOS 13.0, *)
struct Dropdown: View {
    var options: [DropdownOption]
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?
    
    var bropdownHeight: CGFloat {
        return min(CGFloat(self.options.count) * 25, 75);
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(self.options, id: \.self) { option in
                    DropdownRow(option: option, onOptionSelected: self.onOptionSelected)
                }
            }
        }
        .frame(minHeight: self.bropdownHeight, maxHeight: self.bropdownHeight)
        .padding(.vertical, 2)
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

@available(iOS 13.0, *)
struct DropdownSelector: View {
    @State private var shouldShowDropdown = false
    @State private var selectedOption: DropdownOption? = nil
    @Binding var textInputValue: String
    var placeholder: String = ""
    var options: [DropdownOption]
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?
    private let buttonHeight: CGFloat = 45

    var body: some View {
            HStack {
                TextField(placeholder, text: $textInputValue)
                    .font(.system(size: 14))
                    .foregroundColor(Color.black)
                Spacer()
                Button(action: {
                    self.shouldShowDropdown.toggle()
                }){
                    Image(systemName: self.shouldShowDropdown ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .resizable()
                        .frame(width: 14, height: 8)
                        .font(Font.system(size: 14, weight: .medium))
                        .foregroundColor(Color.black)
                }
        }
        .padding(.horizontal)
        .cornerRadius(5)
        .frame(maxWidth: .infinity, minHeight: abs(self.buttonHeight))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
        )
        .overlay(
            VStack {
                if self.shouldShowDropdown {
                    Spacer(minLength: buttonHeight + 1)
                    Dropdown(options: self.options, onOptionSelected: { option in
                        shouldShowDropdown = false
                        selectedOption = option
                        textInputValue = option.value
                        self.onOptionSelected?(option)
                    })
                }
            }, alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 5).fill(Color.white)
        )
    }
}

@available(iOS 13.0, *)
struct DropdownSelector_Previews: PreviewProvider {
    @State private static var textInputValue: String = ""
    static var placeholder: String = "Enter here"
    static var uniqueKey: String {
        UUID().uuidString
    }

    static let options: [DropdownOption] = [
        DropdownOption(key: uniqueKey, value: "A"),
        DropdownOption(key: uniqueKey, value: "B"),
    ]


    static var previews: some View {
        
        VStack(spacing: 20) {
            DropdownSelector(
                textInputValue: $textInputValue,
                placeholder: placeholder,
                options: options,
                onOptionSelected: { option in
                    textInputValue = option.value
                    print(option)
            })
            .padding(.horizontal)
            .zIndex(1)
        }
    }
}
