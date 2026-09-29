// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageFormsExtension on _MachineEntryPageState {
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? _requiredValidator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
    );
  }

  List<Widget> _buildMachineFieldInputs(
    MachineDraft draft, {
    StateSetter? draftStateSetter,
  }) {
    return [
      _buildTextField(controller: draft.nameController, label: 'Machine Name'),
      _buildTextField(
        controller: draft.modelNameController,
        label: 'Model Name',
      ),
      _buildTextField(
        controller: draft.modelNumberController,
        label: 'Model Number',
      ),
      _buildTextField(
        controller: draft.operatingHoursController,
        label: 'Operating Hours',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _numericRequiredValidator,
      ),
      _buildTextField(
        controller: draft.idleHoursController,
        label: 'Idle Hours',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _numericRequiredValidator,
      ),
      _buildTextField(
        controller: draft.lastCheckDateController,
        label: 'Last Check Date (YYYY-MM-DD)',
        keyboardType: TextInputType.datetime,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
          LengthLimitingTextInputFormatter(10),
        ],
        validator: _dateRequiredValidator,
      ),
      _buildTextField(
        controller: draft.serialNumberController,
        label: 'Serial Number',
      ),
      _buildTextField(controller: draft.locationController, label: 'Location'),
      _buildTextField(
        controller: draft.manufacturerController,
        label: 'Manufacturer',
      ),
      _buildTextField(
        controller: draft.maintenanceDocumentNameController,
        label: 'Maintenance Document Name',
      ),
      _buildTextField(
        controller: draft.maintenanceDocumentNumberController,
        label: 'Maintenance Document Number',
      ),
      _buildTextField(
        controller: draft.maintenancePublisherController,
        label: 'Maintenance Publisher',
      ),
      _buildMachineLicenseTypeSection(
        draft,
        draftStateSetter: draftStateSetter,
      ),
    ];
  }

  Widget _buildMachineLicenseTypeSection(
    MachineDraft draft, {
    StateSetter? draftStateSetter,
  }) {
    final updateState = draftStateSetter ?? setState;
    final customLicenses = _customLicenseTypes;
    return Column(
      key: _MachineEntryPageState._licenseTypeSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'License Type (Required Trades)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Tooltip(
              message: 'Add License Type',
              child: IconButton.outlined(
                onPressed: () {
                  _showAddLicenseTypeDialog(
                    onSaved: (type) {
                      updateState(() {
                        draft.additionalRequiredLicenses.add(type);
                      });
                    },
                  );
                },
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Manage License Types',
              child: IconButton.outlined(
                onPressed: () {
                  _showManageLicenseTypesDialog(
                    onRenamed: (oldName, newName) {
                      updateState(() {
                        if (draft.additionalRequiredLicenses.remove(oldName)) {
                          draft.additionalRequiredLicenses.add(newName);
                        }
                      });
                    },
                    onDeleted: (deletedName) {
                      updateState(() {
                        draft.additionalRequiredLicenses.remove(deletedName);
                      });
                    },
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Heating Ventilation Air Conditioning'),
          subtitle: const Text('Requires license'),
          value: draft.requiresHvacLicense,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            updateState(() {
              draft.requiresHvacLicense = value;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Refrigeration'),
          subtitle: const Text('Requires license'),
          value: draft.requiresRefrigerationLicense,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            updateState(() {
              draft.requiresRefrigerationLicense = value;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Plumber'),
          subtitle: const Text('Requires license'),
          value: draft.requiresPlumberLicense,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            updateState(() {
              draft.requiresPlumberLicense = value;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Electrician'),
          subtitle: const Text('Requires license'),
          value: draft.requiresElectricianLicense,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            updateState(() {
              draft.requiresElectricianLicense = value;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Boiler'),
          subtitle: const Text('Requires license'),
          value: draft.requiresBoilerLicense,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            updateState(() {
              draft.requiresBoilerLicense = value;
            });
          },
        ),
        ...customLicenses.map(
          (license) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(license),
            subtitle: const Text('Requires license'),
            value: draft.additionalRequiredLicenses.contains(license),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              updateState(() {
                if (value) {
                  draft.additionalRequiredLicenses.add(license);
                } else {
                  draft.additionalRequiredLicenses.remove(license);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _withVerticalSpacing(List<Widget> children, {double gap = 12}) {
    if (children.isEmpty) {
      return const <Widget>[];
    }

    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        spaced.add(SizedBox(height: gap));
      }
      spaced.add(children[index]);
    }
    return spaced;
  }

  Widget _buildAdaptiveMachineFields(
    MachineDraft draft, {
    StateSetter? draftStateSetter,
  }) {
    final fields = _buildMachineFieldInputs(
      draft,
      draftStateSetter: draftStateSetter,
    );
    final fieldGap = _fieldGapForLayout(_layoutForContext(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 760;
        if (!useTwoColumns) {
          return Column(children: _withVerticalSpacing(fields, gap: fieldGap));
        }

        final spacing = fieldGap;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: fields
              .map((field) {
                final isLicenseSection =
                    field.key is ValueKey<String> &&
                    (field.key as ValueKey<String>).value ==
                        _MachineEntryPageState._licenseTypeSectionKey.value;
                final width = isLicenseSection
                    ? constraints.maxWidth
                    : itemWidth;
                return SizedBox(width: width, child: field);
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSubAssemblyCard({
    required int index,
    required SubAssemblyDraft draft,
    required VoidCallback onChanged,
    required VoidCallback onRemove,
    required ({String name, String number, String publisher}) Function()
    getParentDocValues,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        maintainState: true,
        title: Text('Sub-Assembly ${index + 1}'),
        subtitle: Text(
          draft.nameController.text.trim().isEmpty
              ? 'Tap to enter details'
              : draft.nameController.text.trim(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove Sub-Assembly',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _buildTextField(
                  controller: draft.nameController,
                  label: 'Sub-Assembly Name',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.modelNameController,
                  label: 'Model Name',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.modelNumberController,
                  label: 'Model Number',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.operatingHoursController,
                  label: 'Operating Hours',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _numericRequiredValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.idleHoursController,
                  label: 'Idle Hours',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _numericRequiredValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.serialNumberController,
                  label: 'Serial Number',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.locationController,
                  label: 'Location',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.manufacturerController,
                  label: 'Manufacturer',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Import maintenance document from parent machine',
                  ),
                  value: draft.importDocFromParent,
                  onChanged: (value) {
                    if (value == null) return;
                    draft.importDocFromParent = value;
                    if (value) {
                      final parent = getParentDocValues();
                      draft.maintenanceDocumentNameController.text =
                          parent.name;
                      draft.maintenanceDocumentNumberController.text =
                          parent.number;
                      draft.maintenancePublisherController.text =
                          parent.publisher;
                    }
                    onChanged();
                  },
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: draft.maintenanceDocumentNameController,
                  label: 'Maintenance Document Name',
                  enabled: !draft.importDocFromParent,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.maintenanceDocumentNumberController,
                  label: 'Maintenance Document Number',
                  enabled: !draft.importDocFromParent,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: draft.maintenancePublisherController,
                  label: 'Maintenance Publisher',
                  enabled: !draft.importDocFromParent,
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final superCategoryOptions = _availableSuperCategories;
                    final selectedSuperCategory =
                        draft.superCategory.isNotEmpty &&
                            superCategoryOptions.contains(draft.superCategory)
                        ? draft.superCategory
                        : superCategoryOptions.first;
                    draft.superCategory = selectedSuperCategory;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSuperCategory,
                            decoration: const InputDecoration(
                              labelText: 'Super Category',
                              border: OutlineInputBorder(),
                            ),
                            items: superCategoryOptions
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value == null) return;
                              draft.superCategory = value;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Add Super Category',
                          child: IconButton.outlined(
                            onPressed: () {
                              _showAddSuperCategoryDialog(
                                onSaved: (type) {
                                  draft.superCategory = type;
                                  onChanged();
                                },
                              );
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Manage Super Categories',
                          child: IconButton.outlined(
                            onPressed: () {
                              _showManageSuperCategoriesDialog(
                                onDeleted: (deletedName) {
                                  if (draft.superCategory != deletedName) {
                                    return;
                                  }
                                  final fallback = _availableSuperCategories;
                                  draft.superCategory = fallback.isEmpty
                                      ? ''
                                      : fallback.first;
                                  onChanged();
                                },
                              );
                            },
                            icon: const Icon(Icons.tune),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final subCategoryOptions = _availableSubCategories;
                    final selectedSubCategory =
                        draft.subCategory.isNotEmpty &&
                            subCategoryOptions.contains(draft.subCategory)
                        ? draft.subCategory
                        : subCategoryOptions.first;
                    draft.subCategory = selectedSubCategory;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSubCategory,
                            decoration: const InputDecoration(
                              labelText: 'Sub Category',
                              border: OutlineInputBorder(),
                            ),
                            items: subCategoryOptions
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value == null) return;
                              draft.subCategory = value;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Add Sub Category',
                          child: IconButton.outlined(
                            onPressed: () {
                              _showAddSubCategoryDialog(
                                onSaved: (type) {
                                  draft.subCategory = type;
                                  onChanged();
                                },
                              );
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Manage Sub Categories',
                          child: IconButton.outlined(
                            onPressed: () {
                              _showManageSubCategoriesDialog(
                                onDeleted: (deletedName) {
                                  if (draft.subCategory != deletedName) {
                                    return;
                                  }
                                  final subCategoryOptions =
                                      _availableSubCategories;
                                  draft.subCategory = subCategoryOptions.isEmpty
                                      ? ''
                                      : subCategoryOptions.first;
                                  onChanged();
                                },
                              );
                            },
                            icon: const Icon(Icons.tune),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMaintenanceTaskSection(
                  draft: draft,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubAssemblySection({
    required List<SubAssemblyDraft> drafts,
    required VoidCallback onAdd,
    required VoidCallback onChanged,
    required void Function(int index) onRemove,
    required ({String name, String number, String publisher}) Function()
    getParentDocValues,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sub Assemblies',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Sub-Assembly'),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Sub Assemblies',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sub-Assembly'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        if (drafts.isEmpty)
          const Text('No sub-assemblies added yet.')
        else
          ...List<Widget>.generate(
            drafts.length,
            (index) => _buildSubAssemblyCard(
              index: index,
              draft: drafts[index],
              onChanged: onChanged,
              onRemove: () => onRemove(index),
              getParentDocValues: getParentDocValues,
            ),
          ),
      ],
    );
  }

  Widget _buildMaintenanceTaskSection({
    required SubAssemblyDraft draft,
    required VoidCallback onChanged,
  }) {
    final tasks = draft.maintenanceTaskDrafts;
    final taskTypeOptions = _availableMaintenanceTaskTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintenance Tasks',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          tasks.add(MaintenanceTaskDraft());
                          if (taskTypeOptions.isNotEmpty) {
                            tasks.last.taskType = taskTypeOptions.first;
                          }
                          onChanged();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showAddMaintenanceTaskTypeDialog(
                            onSaved: (_) => onChanged(),
                          );
                        },
                        icon: const Icon(Icons.playlist_add_outlined),
                        label: const Text('Add Task Type'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showManageMaintenanceTaskTypesDialog(
                            onDeleted: (deletedName) {
                              for (final taskDraft in tasks) {
                                if (taskDraft.taskType == deletedName &&
                                    taskTypeOptions.isNotEmpty) {
                                  taskDraft.taskType = taskTypeOptions.first;
                                }
                              }
                              onChanged();
                            },
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Manage Task Types'),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Maintenance Tasks',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    tasks.add(MaintenanceTaskDraft());
                    if (taskTypeOptions.isNotEmpty) {
                      tasks.last.taskType = taskTypeOptions.first;
                    }
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Add Task Type',
                  onPressed: () {
                    _showAddMaintenanceTaskTypeDialog(
                      onSaved: (_) => onChanged(),
                    );
                  },
                  icon: const Icon(Icons.playlist_add_outlined),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: 'Manage Task Types',
                  onPressed: () {
                    _showManageMaintenanceTaskTypesDialog(
                      onDeleted: (deletedName) {
                        for (final taskDraft in tasks) {
                          if (taskDraft.taskType == deletedName &&
                              taskTypeOptions.isNotEmpty) {
                            taskDraft.taskType = taskTypeOptions.first;
                          }
                        }
                        onChanged();
                      },
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Text('No maintenance tasks added yet.')
        else
          ...List<Widget>.generate(tasks.length, (taskIndex) {
            final task = tasks[taskIndex];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Task ${taskIndex + 1}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            tasks.removeAt(taskIndex).dispose();
                            onChanged();
                          },
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove Task',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!taskTypeOptions.contains(task.taskType) &&
                        taskTypeOptions.isNotEmpty)
                      Builder(
                        builder: (_) {
                          task.taskType = taskTypeOptions.first;
                          return const SizedBox.shrink();
                        },
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: task.taskType,
                      decoration: const InputDecoration(
                        labelText: 'Task Type',
                        border: OutlineInputBorder(),
                      ),
                      items: taskTypeOptions
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        task.taskType = value;
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final intervalField = TextFormField(
                          controller: task.timeValueController,
                          decoration: const InputDecoration(
                            labelText: 'Interval',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => onChanged(),
                        );

                        final categoryField = DropdownButtonFormField<String>(
                          initialValue: task.timeCategory,
                          decoration: const InputDecoration(
                            labelText: 'Time Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _maintenanceTimeCategories
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            task.timeCategory = value;
                            onChanged();
                          },
                        );

                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              intervalField,
                              const SizedBox(height: 8),
                              categoryField,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: intervalField),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: categoryField),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Machine _withUpdatedSubAssemblyTasks({
    required Machine machine,
    required int subAssemblyIndex,
    required List<MaintenanceTask> tasks,
  }) {
    final updatedSubAssemblies = List<SubAssembly>.from(machine.subAssemblies);
    final subAssembly = updatedSubAssemblies[subAssemblyIndex];
    updatedSubAssemblies[subAssemblyIndex] = subAssembly.copyWith(
      maintenanceTasks: tasks,
    );
    return machine.copyWith(subAssemblies: updatedSubAssemblies);
  }

  Future<void> _deleteTaskForSubAssembly({
    required Machine machine,
    required int subAssemblyIndex,
    required int taskIndex,
  }) async {
    final subAssembly = machine.subAssemblies[subAssemblyIndex];
    final task = subAssembly.maintenanceTasks[taskIndex];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final layout = _layoutForContext(dialogContext);
        return AlertDialog(
          insetPadding: _dialogInsetPaddingForLayout(layout),
          title: const Text('Delete Task'),
          content: Text(
            'Delete ${task.taskType} every ${task.timeValue} ${task.timeCategory}?',
          ),
          actions: _dialogActionsForContext(dialogContext, [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_cancelActionLabel(dialogContext)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_deleteActionLabel(dialogContext)),
            ),
          ]),
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final updatedTasks = List<MaintenanceTask>.from(
      subAssembly.maintenanceTasks,
    )..removeAt(taskIndex);

    await _updateMachine(
      _withUpdatedSubAssemblyTasks(
        machine: machine,
        subAssemblyIndex: subAssemblyIndex,
        tasks: updatedTasks,
      ),
    );
  }

  Future<void> _addTaskForSubAssembly({
    required Machine machine,
    required int subAssemblyIndex,
  }) async {
    final subAssembly = machine.subAssemblies[subAssemblyIndex];
    final taskTypeOptions = _availableMaintenanceTaskTypes;
    final updatedTasks =
        List<MaintenanceTask>.from(subAssembly.maintenanceTasks)..add(
          MaintenanceTask(
            taskType: taskTypeOptions.first,
            timeCategory: _maintenanceTimeCategories.first,
            timeValue: 1,
          ),
        );

    await _updateMachine(
      _withUpdatedSubAssemblyTasks(
        machine: machine,
        subAssemblyIndex: subAssemblyIndex,
        tasks: updatedTasks,
      ),
    );
  }

  Future<void> _updateTaskForSubAssembly({
    required Machine machine,
    required int subAssemblyIndex,
    required int taskIndex,
    required MaintenanceTask updatedTask,
  }) async {
    final subAssembly = machine.subAssemblies[subAssemblyIndex];
    final updatedTasks = List<MaintenanceTask>.from(
      subAssembly.maintenanceTasks,
    );
    updatedTasks[taskIndex] = updatedTask;

    await _updateMachine(
      _withUpdatedSubAssemblyTasks(
        machine: machine,
        subAssemblyIndex: subAssemblyIndex,
        tasks: updatedTasks,
      ),
    );
  }

  Widget _buildInlineTaskEditorCard({
    required Machine machine,
    required int subAssemblyIndex,
    required int taskIndex,
    required MaintenanceTask task,
  }) {
    final taskTypeOptions = _availableMaintenanceTaskTypes;
    var taskType = task.taskType;
    if (!taskTypeOptions.contains(taskType)) {
      taskType = taskTypeOptions.first;
    }
    var timeCategory = task.timeCategory;
    var timeValueText = '${task.timeValue}';

    return StatefulBuilder(
      builder: (context, setRowState) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Task ${taskIndex + 1}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _deleteTaskForSubAssembly(
                          machine: machine,
                          subAssemblyIndex: subAssemblyIndex,
                          taskIndex: taskIndex,
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete Task',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: taskType,
                  decoration: const InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: taskTypeOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setRowState(() {
                      taskType = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final intervalField = TextFormField(
                      initialValue: timeValueText,
                      decoration: const InputDecoration(
                        labelText: 'Interval',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        timeValueText = value;
                      },
                    );

                    final categoryField = DropdownButtonFormField<String>(
                      initialValue: timeCategory,
                      decoration: const InputDecoration(
                        labelText: 'Time Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _maintenanceTimeCategories
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setRowState(() {
                          timeCategory = value;
                        });
                      },
                    );

                    if (constraints.maxWidth < 560) {
                      return Column(
                        children: [
                          intervalField,
                          const SizedBox(height: 8),
                          categoryField,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: intervalField),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: categoryField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final parsed = int.tryParse(timeValueText.trim()) ?? 1;
                      final normalized = parsed < 1 ? 1 : parsed;
                      await _updateTaskForSubAssembly(
                        machine: machine,
                        subAssemblyIndex: subAssemblyIndex,
                        taskIndex: taskIndex,
                        updatedTask: task.copyWith(
                          taskType: taskType,
                          timeCategory: timeCategory,
                          timeValue: normalized,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Task'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMachineCard(
    Machine machine, {
    required bool showActions,
    required bool editableDetails,
  }) {
    final layout = _layoutForContext(context);
    final cardPadding = _cardPaddingForLayout(layout);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    machine.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (showActions)
                  PopupMenuButton<MachineAction>(
                    onSelected: (action) {
                      if (action == MachineAction.edit) {
                        _editMachine(machine);
                      } else if (action == MachineAction.delete) {
                        _deleteMachine(machine);
                      }
                    },
                    itemBuilder: (_) {
                      return const [
                        PopupMenuItem(
                          value: MachineAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: MachineAction.delete,
                          child: Text('Delete'),
                        ),
                      ];
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Model: ${machine.modelName} (${machine.modelNumber})'),
            Text('Serial: ${machine.serialNumber}'),
            Text('Location: ${machine.location}'),
            Text('Manufacturer: ${machine.manufacturer}'),
            Text('Maintenance Document: ${machine.maintenanceDocumentName}'),
            Text('Document Number: ${machine.maintenanceDocumentNumber}'),
            Text('Publisher: ${machine.maintenancePublisher}'),
            const SizedBox(height: 8),
            _buildMachineLicenseRequirementChips(machine),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Machine Details'),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                if (editableDetails)
                  _buildEditableMachineDetails(machine)
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Operating Hours: ${machine.operatingHours}\n'
                      'Idle Hours: ${machine.idleHours}\n'
                      'Last Check Date (Hours): ${machine.lastCheckDate}',
                    ),
                  ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Sub Assemblies (${machine.subAssemblies.length})'),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: machine.subAssemblies.isEmpty
                  ? const [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No sub-assemblies.'),
                      ),
                    ]
                  : List<Widget>.generate(machine.subAssemblies.length, (
                      index,
                    ) {
                      final subAssembly = machine.subAssemblies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(subAssembly.name),
                          subtitle: Text(
                            '${subAssembly.modelName} (${subAssembly.modelNumber})',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Operating Hours: ${subAssembly.operatingHours}\n'
                                    'Idle Hours: ${subAssembly.idleHours}\n'
                                    'Serial Number: ${subAssembly.serialNumber}\n'
                                    'Location: ${subAssembly.location}\n'
                                    'Manufacturer: ${subAssembly.manufacturer}\n'
                                    'Super Category: ${subAssembly.superCategory}\n'
                                    'Sub Category: ${subAssembly.subCategory}\n'
                                    'Maintenance Document: ${subAssembly.maintenanceDocumentName}\n'
                                    'Document Number: ${subAssembly.maintenanceDocumentNumber}\n'
                                    'Publisher: ${subAssembly.maintenancePublisher}\n'
                                    'Projected Next Date: ${_projectedNextDateLabel(machine, subAssembly)}\n\n'
                                    'Maintenance Tasks:\n'
                                    '${_maintenanceTaskSummary(machine, subAssembly)}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildWorkOrderStatusSummaryChips(
                                    subAssembly,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMaintenanceDueWorkOrderStatusColumns(
                                    subAssembly,
                                  ),
                                  if (editableDetails) ...[
                                    const SizedBox(height: 12),
                                    _buildEditableSubAssemblyDetails(
                                      machine: machine,
                                      subAssembly: subAssembly,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (showActions)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _addTaskForSubAssembly(
                                          machine: machine,
                                          subAssemblyIndex: index,
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Task'),
                                    ),
                                    const SizedBox(height: 8),
                                    if (subAssembly.maintenanceTasks.isEmpty)
                                      const Text('No tasks available to edit.')
                                    else
                                      ...List<Widget>.generate(
                                        subAssembly.maintenanceTasks.length,
                                        (taskIndex) {
                                          final task = subAssembly
                                              .maintenanceTasks[taskIndex];
                                          return _buildInlineTaskEditorCard(
                                            machine: machine,
                                            subAssemblyIndex: index,
                                            taskIndex: taskIndex,
                                            task: task,
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskFilterCard() {
    final layout = _layoutForContext(context);
    final cardPadding = _cardPaddingForLayout(layout);

    final superCategoryField = DropdownButtonFormField<String?>(
      initialValue: _selectedSuperCategory,
      decoration: const InputDecoration(
        labelText: 'Super Category',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Super Categories'),
        ),
        ..._availableSuperCategories.map(
          (type) => DropdownMenuItem<String?>(value: type, child: Text(type)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSuperCategory = value;
        });
      },
    );

    final subCategoryField = DropdownButtonFormField<String?>(
      initialValue: _selectedSubCategory,
      decoration: const InputDecoration(
        labelText: 'Sub Category',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Sub Categories'),
        ),
        ..._availableSubCategories.map(
          (type) => DropdownMenuItem<String?>(value: type, child: Text(type)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSubCategory = value;
        });
      },
    );

    final taskTypeField = DropdownButtonFormField<String?>(
      initialValue: _selectedTaskType,
      decoration: const InputDecoration(
        labelText: 'Task Type',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Task Types'),
        ),
        ..._availableMaintenanceTaskTypes.map(
          (taskType) =>
              DropdownMenuItem<String?>(value: taskType, child: Text(taskType)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTaskType = value;
        });
      },
    );

    final dueCategoryField = DropdownButtonFormField<String?>(
      initialValue: _selectedTaskTimeCategory,
      decoration: const InputDecoration(
        labelText: 'Due Time Category',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Categories'),
        ),
        ..._maintenanceTimeCategories.map(
          (category) =>
              DropdownMenuItem<String?>(value: category, child: Text(category)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTaskTimeCategory = value;
        });
      },
    );

    final searchField = TextFormField(
      controller: _taskSearchController,
      decoration: const InputDecoration(
        labelText: 'Search Machine, Sub-Assembly, or Task',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _taskSearchQuery = value;
        });
      },
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Filter', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoColumn = constraints.maxWidth >= 760;
                if (!isTwoColumn) {
                  return Column(
                    children: [
                      superCategoryField,
                      const SizedBox(height: 12),
                      subCategoryField,
                      const SizedBox(height: 12),
                      taskTypeField,
                      const SizedBox(height: 12),
                      dueCategoryField,
                      const SizedBox(height: 12),
                      searchField,
                    ],
                  );
                }

                const spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(width: itemWidth, child: superCategoryField),
                    SizedBox(width: itemWidth, child: subCategoryField),
                    SizedBox(width: itemWidth, child: taskTypeField),
                    SizedBox(width: itemWidth, child: dueCategoryField),
                    SizedBox(width: itemWidth, child: searchField),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _hasTaskFilter
                    ? () {
                        setState(() {
                          _selectedTaskType = null;
                          _selectedTaskTimeCategory = null;
                          _selectedSuperCategory = null;
                          _selectedSubCategory = null;
                          _taskSearchQuery = '';
                          _taskSearchController.clear();
                        });
                      }
                    : null,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineEntryForm() {
    final layout = _layoutForContext(context);
    final cardPadding = _cardPaddingForLayout(layout);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdaptiveMachineFields(_machineDraft),
              const SizedBox(height: 16),
              _buildSubAssemblySection(
                drafts: _subAssemblyDrafts,
                onAdd: () {
                  setState(() {
                    _subAssemblyDrafts.add(SubAssemblyDraft());
                  });
                },
                onChanged: () {
                  setState(() {});
                },
                onRemove: (index) {
                  setState(() {
                    final removed = _subAssemblyDrafts.removeAt(index);
                    removed.dispose();
                  });
                },
                getParentDocValues: () => (
                  name: _machineDraft.maintenanceDocumentNameController.text,
                  number:
                      _machineDraft.maintenanceDocumentNumberController.text,
                  publisher: _machineDraft.maintenancePublisherController.text,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMachine,
                  child: const Text('Add Machine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineList(
    List<Machine> machines, {
    required bool showActions,
    required bool editableDetails,
    required String emptyMessage,
  }) {
    if (machines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emptyMessage),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _reloadMachinesFromDatabase(showFeedback: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Data'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1300 ? 3 : (width >= 900 ? 2 : 1);
        final spacing = 12.0;
        final itemWidth = columns == 1
            ? width
            : ((width - ((columns - 1) * spacing)) / columns);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: machines
              .map(
                (machine) => SizedBox(
                  width: itemWidth,
                  child: _buildMachineCard(
                    machine,
                    showActions: showActions,
                    editableDetails: editableDetails,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _machineDraft.clear();
    _disposeSubAssemblyDrafts(_subAssemblyDrafts);
    _subAssemblyDrafts.clear();
  }

  Future<void> _saveMachine() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final machine = _machineDraft.toMachine(
      subAssemblies: _currentSubAssembliesFromDrafts(_subAssemblyDrafts),
    );

    final internalConflict = _checkInternalDocumentNumberDuplicates(machine);
    if (internalConflict != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(internalConflict)));
      return;
    }

    try {
      final persistedConflict = await _checkPersistedDocumentNumberConflicts(
        machine,
      );
      if (persistedConflict != null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(persistedConflict)));
        return;
      }

      await MachineDatabase.instance.insertMachine(machine);

      if (!mounted) {
        return;
      }

      await _loadMachines(seedSampleData: false);

      if (!mounted) {
        return;
      }

      _resetForm();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Machine saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorSnackBar('Failed to save machine.', error);
    }
  }

  Future<void> _editMachine(Machine machine) async {
    final machineDraft = MachineDraft(machine: machine);
    final subAssemblyDrafts = machine.subAssemblies
        .map((subAssembly) => SubAssemblyDraft(subAssembly: subAssembly))
        .toList(growable: true);
    final formKey = GlobalKey<FormState>();

    final updatedMachine = await showDialog<Machine>(
      context: context,
      builder: (dialogContext) {
        final layout = _layoutForContext(dialogContext);
        final dialogMaxWidth = _dialogMaxWidthForLayout(layout);
        final dialogWidth = (MediaQuery.sizeOf(dialogContext).width * 0.92)
            .clamp(320.0, dialogMaxWidth)
            .toDouble();
        final dialogInsetPadding = _dialogInsetPaddingForLayout(layout);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              insetPadding: dialogInsetPadding,
              title: const Text('Edit Machine'),
              content: SizedBox(
                width: dialogWidth,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAdaptiveMachineFields(
                          machineDraft,
                          draftStateSetter: setDialogState,
                        ),
                        const SizedBox(height: 16),
                        _buildSubAssemblySection(
                          drafts: subAssemblyDrafts,
                          onAdd: () {
                            setDialogState(() {
                              subAssemblyDrafts.add(SubAssemblyDraft());
                            });
                          },
                          onChanged: () {
                            setDialogState(() {});
                          },
                          onRemove: (index) {
                            setDialogState(() {
                              final removed = subAssemblyDrafts.removeAt(index);
                              removed.dispose();
                            });
                          },
                          getParentDocValues: () => (
                            name: machineDraft
                                .maintenanceDocumentNameController
                                .text,
                            number: machineDraft
                                .maintenanceDocumentNumberController
                                .text,
                            publisher: machineDraft
                                .maintenancePublisherController
                                .text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_cancelActionLabel(dialogContext)),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      machineDraft.toMachine(
                        id: machine.id,
                        subAssemblies: _currentSubAssembliesFromDrafts(
                          subAssemblyDrafts,
                        ),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ]),
            );
          },
        );
      },
    );

    machineDraft.dispose();
    _disposeSubAssemblyDrafts(subAssemblyDrafts);

    if (!mounted) {
      return;
    }

    if (updatedMachine == null) {
      return;
    }

    if (updatedMachine.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to edit machine without id.')),
      );
      return;
    }

    final internalConflict = _checkInternalDocumentNumberDuplicates(
      updatedMachine,
    );
    if (internalConflict != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(internalConflict)));
      return;
    }

    await _updateMachine(updatedMachine);
  }

  Future<void> _updateMachine(
    Machine updatedMachine, {
    bool showSuccessMessage = true,
  }) async {
    if (updatedMachine.id == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update machine without id.')),
      );
      return;
    }

    final internalConflict = _checkInternalDocumentNumberDuplicates(
      updatedMachine,
    );
    if (internalConflict != null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(internalConflict)));
      return;
    }

    try {
      final persistedConflict = await _checkPersistedDocumentNumberConflicts(
        updatedMachine,
        editingMachineId: updatedMachine.id,
      );
      if (persistedConflict != null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(persistedConflict)));
        return;
      }

      final changed = await MachineDatabase.instance.updateMachine(
        updatedMachine,
      );

      if (!mounted) {
        return;
      }

      if (changed == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Machine not found.')));
        return;
      }

      await _loadMachines(seedSampleData: false);

      if (!mounted) {
        return;
      }

      final refreshedMachine = _machines
          .where((machine) => machine.id == updatedMachine.id)
          .cast<Machine?>()
          .firstWhere((_) => true, orElse: () => null);
      final machineId = updatedMachine.id;
      if (machineId != null && refreshedMachine != null) {
        _maintenanceDueDetailDrafts[machineId]?.syncFromMachine(
          refreshedMachine,
        );
        _machineDetailHistoryFutures.remove(machineId);
      }

      if (showSuccessMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Machine updated.')));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorSnackBar('Failed to update machine.', error);
    }
  }

  Future<void> _deleteMachine(Machine machine) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final layout = _layoutForContext(dialogContext);
        return AlertDialog(
          insetPadding: _dialogInsetPaddingForLayout(layout),
          title: const Text('Delete Machine'),
          content: Text('Delete ${machine.name}?'),
          actions: _dialogActionsForContext(dialogContext, [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_cancelActionLabel(dialogContext)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_deleteActionLabel(dialogContext)),
            ),
          ]),
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (machine.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete machine without id.')),
      );
      return;
    }

    try {
      final removed = await MachineDatabase.instance.deleteMachine(machine.id!);

      if (!mounted) {
        return;
      }

      if (removed == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Machine not found.')));
        return;
      }

      setState(() {
        _machines.removeWhere((m) => m.id == machine.id);
        final machineId = machine.id;
        if (machineId != null) {
          _maintenanceDueDetailDrafts.remove(machineId)?.dispose();
          _machineDetailHistoryFutures.remove(machineId);
        }
        _pruneMaintenanceDueState();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Machine deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorSnackBar('Failed to delete machine.', error);
    }
  }

  Widget _buildAddMachineTab() {
    return ListView(children: [_buildMachineEntryForm()]);
  }

  Future<void> _printMachinesListPdf() async {
    _ensureMachinesVisible();
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final yyyy = now.year.toString().padLeft(4, '0');
    final fileName = 'machineslist$mm$dd$yyyy.pdf';
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '$fileName | ${_formatDate(now)} | Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          );
        },
        build: (context) {
          return [
            pw.Text(
              'Machines List Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated: ${_formatDate(now)}'),
            pw.SizedBox(height: 4),
            pw.Text('Total Machines: ${_machines.length}'),
            pw.SizedBox(height: 12),
            ..._machines.map((machine) {
              final licenseTrades = _machineLicenseTradeLabels(machine);
              final licenseSummary = licenseTrades.isEmpty
                  ? 'None'
                  : licenseTrades.join(', ');
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      machine.name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Model: ${machine.modelName} (${machine.modelNumber})',
                    ),
                    pw.Text('Location: ${machine.location}'),
                    pw.Text('Manufacturer: ${machine.manufacturer}'),
                    pw.Text(
                      'Operating / Idle Hours: ${machine.operatingHours} / ${machine.idleHours}',
                    ),
                    pw.Text('Last Check: ${machine.lastCheckDate}'),
                    pw.Text('Required Licenses: $licenseSummary'),
                    pw.Text('Sub-Assemblies: ${machine.subAssemblies.length}'),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final pdfBytes = await document.save();
    await _presentPdfForPrinting(
      fileName,
      pdfBytes,
      successMessage:
          'Opened $fileName in your default PDF viewer. Use the viewer print command to print it.',
    );
  }

  Widget _buildMachinesListTab() {
    _ensureMachinesVisible();
    return ListView(
      children: [
        _buildMachinesPdfActionCard(
          title: 'Machines List',
          description: 'Export the current machines list to PDF.',
        ),
        const SizedBox(height: 12),
        _buildMachineList(
          _machines,
          showActions: false,
          editableDetails: false,
          emptyMessage: 'No machines added yet.',
        ),
      ],
    );
  }

  Widget _buildMachinesPdfActionCard({
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _printMachinesListPdf,
                    icon: Icon(_pdfActionIcon),
                    label: Text(_machinesListPdfActionLabel),
                  ),
                  if (_opensPdfInViewerForPrinting) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 320,
                      child: _buildPdfActionHint('the machines list PDF'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
