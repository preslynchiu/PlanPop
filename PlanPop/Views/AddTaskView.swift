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

    // Form state
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var hasReminder: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var priority: Int = 2

    // UI state
    @State private var showingDeleteAlert = false

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
        }
    }

    // MARK: - Methods

    /// Load existing task data when editing
    private func loadTaskData() {
        guard let task = taskToEdit else { return }

        title = task.title
        notes = task.notes
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? Date()
        hasReminder = task.hasReminder
        reminderDate = task.reminderDate ?? Date()
        selectedCategoryId = task.categoryId
        priority = task.priority
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
