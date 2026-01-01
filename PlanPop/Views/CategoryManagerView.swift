//
//  CategoryManagerView.swift
//  PlanPop
//
//  View for managing task categories
//

import SwiftUI

/// View for managing categories (add, edit, delete)
struct CategoryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel

    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var showingLimitAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                if viewModel.categories.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.textSecondary)

                        Text("No Categories")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create categories to organize your tasks")
                            .font(.body)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.categories) { category in
                            CategoryRow(category: category) {
                                categoryToEdit = category
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if viewModel.canAddCategory {
                            showingAddCategory = true
                        } else {
                            showingLimitAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                EditCategoryView(category: nil)
            }
            .sheet(item: $categoryToEdit) { category in
                EditCategoryView(category: category)
            }
            .alert("Category Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Free users can have up to 3 categories. Upgrade to Premium for unlimited categories!")
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteCategory(viewModel.categories[index])
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Icon with color
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                }

                // Name
                Text(category.name)
                    .font(.body)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Edit Category View

struct EditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel

    // Category to edit (nil for new)
    var category: Category?

    @State private var name: String = ""
    @State private var selectedColor: String = Category.pastelColors[0]
    @State private var selectedIcon: String = Category.availableIcons[0]

    var isEditing: Bool {
        category != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section("Name") {
                    TextField("Category name", text: $name)
                }

                // Color section
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Category.pastelColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 44, height: 44)

                                    if selectedColor == colorHex {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 3)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Icon section
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(Category.availableIcons, id: \.self) { iconName in
                            Button {
                                selectedIcon = iconName
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == iconName ?
                                              Color(hex: selectedColor) :
                                              Color(hex: selectedColor).opacity(0.2))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: iconName)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == iconName ?
                                                        .white :
                                                        Color(hex: selectedColor))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: selectedIcon)
                                .foregroundColor(Color(hex: selectedColor))
                        }

                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundColor(name.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCategoryData()
            }
        }
    }

    private func loadCategoryData() {
        guard let category = category else { return }

        name = category.name
        selectedColor = category.colorHex
        selectedIcon = category.iconName
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var existingCategory = category {
            // Update existing
            existingCategory.name = trimmedName
            existingCategory.colorHex = selectedColor
            existingCategory.iconName = selectedIcon
            viewModel.updateCategory(existingCategory)
        } else {
            // Create new
            let newCategory = Category(
                name: trimmedName,
                colorHex: selectedColor,
                iconName: selectedIcon
            )
            _ = viewModel.addCategory(newCategory)
        }

        dismiss()
    }
}

// MARK: - Previews

#Preview("Category Manager") {
    CategoryManagerView()
        .environmentObject(TaskViewModel())
}

#Preview("Edit Category") {
    EditCategoryView(category: nil)
        .environmentObject(TaskViewModel())
}
