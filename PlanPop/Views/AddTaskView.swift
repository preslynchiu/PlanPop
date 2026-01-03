//
//  AddTaskView.swift
//  PlanPop
//
//  View for adding or editing a task
//

import SwiftUI

/// Form for creating or editing a task
struct AddTaskView: View {
    // Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel

    // Task being edited (nil for new task)
    var taskToEdit: Task?

    // Pre-filled values from suggestion (optional)
    var suggestedTitle: String?
    var suggestedCategoryId: UUID?

    // Form state
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var hasReminder: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var priority: Int = 2
    @State private var selectedIcon: String? = nil

    // UI state
    @State private var showingDeleteAlert = false
    @State private var showingPremiumInfo = false

    // Is this editing an existing task?
    var isEditing: Bool {
        taskToEdit != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Task details section
                Section {
                    // Title field
                    TextField("What do you need to do?", text: $title)
                        .font(.body)

                    // Notes field
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                }

                // Due date section
                Section {
                    Toggle("Set due date", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.primary)
                    }
                }

                // Reminder section
                Section {
                    Toggle("Remind me", isOn: $hasReminder.animation())

                    if hasReminder {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .tint(Theme.primary)
                    }
                } footer: {
                    if hasReminder {
                        Text("You'll receive a notification at this time")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // Category section
                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // "None" option
                            CategoryChip(
                                name: "None",
                                color: Theme.textSecondary,
                                isSelected: selectedCategoryId == nil
                            ) {
                                selectedCategoryId = nil
                            }

                            // Available categories
                            ForEach(viewModel.categories) { category in
                                CategoryChip(
                                    name: category.name,
                                    color: category.color,
                                    iconName: category.iconName,
                                    isSelected: selectedCategoryId == category.id
                                ) {
                                    selectedCategoryId = category.id
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Priority section
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                // Icon section (premium feature)
                Section {
                    if viewModel.settings.isPremium {
                        iconPickerGrid
                    } else {
                        Button {
                            showingPremiumInfo = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Text("Task Icons")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("Premium")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Icon")
                        if !viewModel.settings.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }

                // Delete button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Task")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Task?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let task = taskToEdit {
                        viewModel.deleteTask(task)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .onAppear {
                loadTaskData()
            }
            .sheet(isPresented: $showingPremiumInfo) {
                PremiumInfoView()
            }
        }
    }

    // MARK: - Icon Picker Grid

    private var iconPickerGrid: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                // "None" option
                Button {
                    selectedIcon = nil
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedIcon == nil ? Theme.primary : Theme.primary.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(selectedIcon == nil ? .white : Theme.primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Icon options
                ForEach(Task.availableIcons, id: \.self) { iconName in
                    Button {
                        selectedIcon = iconName
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedIcon == iconName ? Theme.primary : Theme.primary.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundColor(selectedIcon == iconName ? .white : Theme.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)

            // Preview
            if let icon = selectedIcon {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.primary)
                    }
                    Text(title.isEmpty ? "Task Preview" : title)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding(12)
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
            }
        }
    }

    // MARK: - Methods

    /// Load existing task data when editing, or pre-fill from suggestion
    private func loadTaskData() {
        if let task = taskToEdit {
            // Editing existing task
            title = task.title
            notes = task.notes
            hasDueDate = task.dueDate != nil
            dueDate = task.dueDate ?? Date()
            hasReminder = task.hasReminder
            reminderDate = task.reminderDate ?? Date()
            selectedCategoryId = task.categoryId
            priority = task.priority
            selectedIcon = task.iconName
        } else {
            // New task - check for suggestions
            if let suggestedTitle = suggestedTitle {
                title = suggestedTitle
            }
            if let suggestedCategoryId = suggestedCategoryId {
                selectedCategoryId = suggestedCategoryId
            }
        }
    }

    /// Save the task (create new or update existing)
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        if var task = taskToEdit {
            // Update existing task
            task.title = trimmedTitle
            task.notes = notes
            task.dueDate = hasDueDate ? dueDate : nil
            task.hasReminder = hasReminder
            task.reminderDate = hasReminder ? reminderDate : nil
            task.categoryId = selectedCategoryId
            task.priority = priority
            task.iconName = selectedIcon

            viewModel.updateTask(task)
        } else {
            // Create new task
            var newTask = Task(title: trimmedTitle)
            newTask.notes = notes
            newTask.dueDate = hasDueDate ? dueDate : nil
            newTask.hasReminder = hasReminder
            newTask.reminderDate = hasReminder ? reminderDate : nil
            newTask.categoryId = selectedCategoryId
            newTask.priority = priority
            newTask.iconName = selectedIcon

            viewModel.addTask(newTask)
        }

        dismiss()
    }
}

// MARK: - Category Chip Component

struct CategoryChip: View {
    let name: String
    let color: Color
    var iconName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.caption)
                }
                Text(name)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Add Task") {
    AddTaskView()
        .environmentObject(TaskViewModel())
}

#Preview("Edit Task") {
    AddTaskView(taskToEdit: Task.sampleTasks[0])
        .environmentObject(TaskViewModel())
}
