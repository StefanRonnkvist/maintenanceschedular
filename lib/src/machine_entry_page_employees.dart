// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageEmployeesExtension on _MachineEntryPageState {
  Future<void> _loadEmployeeListViewPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final savedQuery =
        preferences.getString(
          _MachineEntryPageState._employeeSearchPreferenceKey,
        ) ??
        '';
    final savedSkill = preferences.getString(
      _MachineEntryPageState._employeeFilterSkillPreferenceKey,
    );
    final savedSort =
        preferences.getString(
          _MachineEntryPageState._employeeSortPreferenceKey,
        ) ??
        _EmployeeSortMode.nameAsc.name;

    final resolvedSort = _EmployeeSortMode.values.where((mode) {
      return mode.name == savedSort;
    }).firstOrNull;

    if (!mounted) {
      return;
    }

    setState(() {
      _employeeSearchQuery = savedQuery;
      _employeeSearchController.text = savedQuery;
      _selectedEmployeeFilterSkill = (savedSkill == null || savedSkill.isEmpty)
          ? null
          : savedSkill;
      _employeeSortMode = resolvedSort ?? _EmployeeSortMode.nameAsc;
    });
  }

  Future<void> _persistEmployeeListViewPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _MachineEntryPageState._employeeSearchPreferenceKey,
      _employeeSearchQuery,
    );

    final selectedSkill = _selectedEmployeeFilterSkill?.trim();
    if (selectedSkill == null || selectedSkill.isEmpty) {
      await preferences.remove(
        _MachineEntryPageState._employeeFilterSkillPreferenceKey,
      );
    } else {
      await preferences.setString(
        _MachineEntryPageState._employeeFilterSkillPreferenceKey,
        selectedSkill,
      );
    }

    await preferences.setString(
      _MachineEntryPageState._employeeSortPreferenceKey,
      _employeeSortMode.name,
    );
  }

  Future<void> _initializeEmployeeSkills() async {
    try {
      final existing = await MachineDatabase.instance.getSkillTypes();
      if (existing.isEmpty) {
        await MachineDatabase.instance.ensureDefaultSkillTypes(
          _MachineEntryPageState._defaultEmployeeSkills,
        );
      }
      await _refreshSkillTypes();
    } catch (_) {
      // Keep default skills available in-memory if DB access fails.
    }
  }

  Future<void> _refreshSkillTypes({String? selectedSkill}) async {
    final savedSkills = await MachineDatabase.instance.getSkillTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _skillTypeOptions
        ..clear()
        ..addAll(savedSkills);
      _hasLoadedSkillTypes = true;

      final available = _availableSkillTypes
          .map((skill) => skill.trim().toUpperCase())
          .toSet();
      _selectedEmployeeSkills.removeWhere(
        (skill) => !available.contains(skill.trim().toUpperCase()),
      );
      if (_selectedEmployeeFilterSkill != null &&
          !available.contains(
            _selectedEmployeeFilterSkill!.trim().toUpperCase(),
          )) {
        _selectedEmployeeFilterSkill = null;
      }
      if (selectedSkill != null && selectedSkill.trim().isNotEmpty) {
        _selectedEmployeeSkills.add(selectedSkill.trim());
      }
    });

    await _persistEmployeeListViewPreferences();
  }

  List<Employee> _visibleEmployees() {
    final query = _employeeSearchQuery.trim().toLowerCase();
    final filtered = _employees
        .where((employee) {
          final matchesQuery =
              query.isEmpty || employee.name.toLowerCase().contains(query);

          final selectedSkill = _selectedEmployeeFilterSkill?.trim();
          final matchesSkill =
              selectedSkill == null ||
              selectedSkill.isEmpty ||
              employee.skills.any(
                (skill) =>
                    skill.trim().toUpperCase() == selectedSkill.toUpperCase(),
              );

          return matchesQuery && matchesSkill;
        })
        .toList(growable: false);

    int compareName(Employee a, Employee b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());

    filtered.sort((a, b) {
      switch (_employeeSortMode) {
        case _EmployeeSortMode.nameAsc:
          return compareName(a, b);
        case _EmployeeSortMode.nameDesc:
          return compareName(b, a);
        case _EmployeeSortMode.skillCountDesc:
          final byCount = b.skills.length.compareTo(a.skills.length);
          if (byCount != 0) {
            return byCount;
          }
          return compareName(a, b);
      }
    });

    return filtered;
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await MachineDatabase.instance.getEmployees();
      if (!mounted) {
        return;
      }

      setState(() {
        _employees
          ..clear()
          ..addAll(employees);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to load employees.', error);
    }
  }

  Future<void> _showAddSkillTypeDialog({
    void Function(String skill)? onSaved,
  }) async {
    final controller = TextEditingController();
    try {
      final enteredSkill = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Skill'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Skill',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = enteredSkill?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }

      final savedSkill = await MachineDatabase.instance.addSkillType(
        normalized,
      );
      if (savedSkill == null || savedSkill.trim().isEmpty) {
        return;
      }

      final finalSkill = savedSkill.trim();
      await _refreshSkillTypes(selectedSkill: finalSkill);
      onSaved?.call(finalSkill);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Skill "$finalSkill" saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save skill.', error);
    } finally {
      controller.dispose();
    }
  }

  Future<String?> _showRenameSkillTypeDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    try {
      final nextName = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Rename Skill'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Skill',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = nextName?.trim() ?? '';
      if (normalized.isEmpty ||
          normalized.toUpperCase() == currentName.toUpperCase()) {
        return null;
      }

      final renamed = await MachineDatabase.instance.renameSkillType(
        currentName,
        normalized,
      );
      if (renamed == null || renamed.trim().isEmpty) {
        return null;
      }

      final renamedTrimmed = renamed.trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skill "$currentName" renamed to "$renamedTrimmed".'),
          ),
        );
      }

      return renamedTrimmed;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to rename skill.', error);
      }
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirmDeleteSkillType(String skill) async {
    try {
      final usageCount = await MachineDatabase.instance
          .getEmployeeSkillUsageCount(skill);
      if (!mounted) {
        return false;
      }

      if (usageCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Cannot Delete Skill'),
              content: Text(
                '"$skill" is currently used by $usageCount employee(s). Remove it from those employees before deleting this skill.',
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ]),
            );
          },
        );
        return false;
      }

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Skill'),
            content: Text('Delete "$skill"?'),
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
        return false;
      }

      await MachineDatabase.instance.deleteSkillType(skill);
      await _refreshSkillTypes();
      await _loadEmployees();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Skill "$skill" deleted.')));
      }

      return true;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete skill.', error);
      }
      return false;
    }
  }

  Future<void> _showManageSkillTypesDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final skills = _availableSkillTypes;
            return AlertDialog(
              title: const Text('Manage Skills'),
              content: SizedBox(
                width: 560,
                child: skills.isEmpty
                    ? const Text('No skills available.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: skills.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          return ListTile(
                            title: Text(skill),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Rename',
                                  onPressed: () async {
                                    final renamedTo =
                                        await _showRenameSkillTypeDialog(skill);
                                    if (renamedTo == null || !mounted) {
                                      return;
                                    }

                                    setState(() {
                                      if (_selectedEmployeeSkills.remove(
                                        skill,
                                      )) {
                                        _selectedEmployeeSkills.add(renamedTo);
                                      }
                                    });

                                    await _refreshSkillTypes();
                                    await _loadEmployees();
                                    if (dialogContext.mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final shouldDelete =
                                        await _confirmDeleteSkillType(skill);
                                    if (!shouldDelete || !mounted) {
                                      return;
                                    }
                                    if (dialogContext.mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                TextButton(
                  onPressed: () async {
                    await _showAddSkillTypeDialog();
                    if (dialogContext.mounted) {
                      setDialogState(() {});
                    }
                  },
                  child: const Text('Add Skill'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _addEmployee() async {
    final name = _employeeNameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee name is required.')),
      );
      return;
    }

    try {
      await MachineDatabase.instance.insertEmployee(
        Employee(
          name: name,
          skills: _selectedEmployeeSkills
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList(growable: false),
          licenses: _selectedEmployeeLicenses
              .map((license) => license.trim())
              .where((license) => license.isNotEmpty)
              .toList(growable: false),
        ),
      );

      _employeeNameController.clear();
      setState(() {
        _selectedEmployeeSkills.clear();
        _selectedEmployeeLicenses.clear();
      });
      await _loadEmployees();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Employee saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save employee.', error);
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final controller = TextEditingController(text: employee.name);
    final selectedSkills = Set<String>.from(employee.skills);
    final selectedLicenses = Set<String>.from(employee.licenses);

    final updated = await showDialog<Employee>(
      context: context,
      builder: (dialogContext) {
        final dialogLayout = _layoutForContext(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final allSkills = _availableSkillTypes;
            return AlertDialog(
              insetPadding: _dialogInsetPaddingForLayout(dialogLayout),
              title: const Text('Edit Employee'),
              content: SizedBox(
                width: _dialogMaxWidthForLayout(dialogLayout),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Employee Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Skills',
                        style: Theme.of(dialogContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...allSkills.map(
                        (skill) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(skill),
                          value: selectedSkills.contains(skill),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              if (value) {
                                selectedSkills.add(skill);
                              } else {
                                selectedSkills.remove(skill);
                              }
                            });
                          },
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showAddSkillTypeDialog(
                                onSaved: (skill) {
                                  setDialogState(() {
                                    selectedSkills.add(skill);
                                  });
                                },
                              );
                              if (dialogContext.mounted) {
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Skill'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showManageSkillTypesDialog();
                              if (dialogContext.mounted) {
                                final refreshed = await MachineDatabase.instance
                                    .getEmployees();
                                final refreshedEmployee = refreshed.firstWhere(
                                  (e) => e.id == employee.id,
                                  orElse: () => employee,
                                );
                                setDialogState(() {
                                  selectedSkills
                                    ..clear()
                                    ..addAll(refreshedEmployee.skills);
                                });
                              }
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Manage Skills'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Licenses',
                        style: Theme.of(dialogContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._availableLicenseTypes.map(
                        (license) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(license),
                          value: selectedLicenses.contains(license),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              if (value) {
                                selectedLicenses.add(license);
                              } else {
                                selectedLicenses.remove(license);
                              }
                            });
                          },
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showAddLicenseTypeDialog(
                                onSaved: (license) {
                                  setDialogState(() {
                                    selectedLicenses.add(license);
                                  });
                                },
                              );
                              if (dialogContext.mounted) {
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add License'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _showManageLicenseTypesDialog(
                                onRenamed: (oldName, newName) {
                                  setDialogState(() {
                                    if (selectedLicenses.remove(oldName)) {
                                      selectedLicenses.add(newName);
                                    }
                                  });
                                },
                                onDeleted: (deletedName) {
                                  setDialogState(() {
                                    selectedLicenses.remove(deletedName);
                                  });
                                },
                              );
                              if (dialogContext.mounted) {
                                setDialogState(() {});
                              }
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Manage Licenses'),
                          ),
                        ],
                      ),
                    ],
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
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      employee.copyWith(
                        name: name,
                        skills: selectedSkills
                            .map((skill) => skill.trim())
                            .where((skill) => skill.isNotEmpty)
                            .toList(growable: false),
                        licenses: selectedLicenses
                            .map((license) => license.trim())
                            .where((license) => license.isNotEmpty)
                            .toList(growable: false),
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

    controller.dispose();

    if (updated == null) {
      return;
    }

    try {
      await MachineDatabase.instance.updateEmployee(updated);
      await _loadEmployees();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Employee updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to update employee.', error);
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Employee'),
          content: Text('Delete "${employee.name}"?'),
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

    final employeeId = employee.id;
    if (employeeId == null) {
      return;
    }

    try {
      await MachineDatabase.instance.deleteEmployee(employeeId);
      await _loadEmployees();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Employee deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to delete employee.', error);
    }
  }

  Widget _buildEmployeesTab() {
    final availableSkills = _availableSkillTypes;
    final availableLicenses = _availableLicenseTypes;
    final visibleEmployees = _visibleEmployees();
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Employee',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _employeeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Skills',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Tooltip(
                      message: 'Add Skill',
                      child: IconButton.outlined(
                        onPressed: () {
                          _showAddSkillTypeDialog(
                            onSaved: (skill) {
                              setState(() {
                                _selectedEmployeeSkills.add(skill);
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Manage Skills',
                      child: IconButton.outlined(
                        onPressed: _showManageSkillTypesDialog,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                  ],
                ),
                if (availableSkills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No skills available. Add a skill to continue.',
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSkills
                        .map(
                          (skill) => FilterChip(
                            label: Text(skill),
                            selected: _selectedEmployeeSkills.contains(skill),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEmployeeSkills.add(skill);
                                } else {
                                  _selectedEmployeeSkills.remove(skill);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Licenses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Tooltip(
                      message: 'Add License',
                      child: IconButton.outlined(
                        onPressed: () {
                          _showAddLicenseTypeDialog(
                            onSaved: (license) {
                              setState(() {
                                _selectedEmployeeLicenses.add(license);
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Manage Licenses',
                      child: IconButton.outlined(
                        onPressed: () {
                          _showManageLicenseTypesDialog(
                            onRenamed: (oldName, newName) {
                              setState(() {
                                if (_selectedEmployeeLicenses.remove(oldName)) {
                                  _selectedEmployeeLicenses.add(newName);
                                }
                              });
                            },
                            onDeleted: (deletedName) {
                              setState(() {
                                _selectedEmployeeLicenses.remove(deletedName);
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                  ],
                ),
                if (availableLicenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No licenses available. Add a license to continue.',
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableLicenses
                        .map(
                          (license) => FilterChip(
                            label: Text(license),
                            selected: _selectedEmployeeLicenses.contains(
                              license,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEmployeeLicenses.add(license);
                                } else {
                                  _selectedEmployeeLicenses.remove(license);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _addEmployee,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Save Employee'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employees',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _employeeSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Employees',
                    hintText: 'Search by employee name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _employeeSearchQuery = value;
                    });
                    _persistEmployeeListViewPreferences();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedEmployeeFilterSkill,
                        decoration: const InputDecoration(
                          labelText: 'Filter By Skill',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Skills'),
                          ),
                          ...availableSkills.map(
                            (skill) => DropdownMenuItem<String?>(
                              value: skill,
                              child: Text(skill),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployeeFilterSkill = value;
                          });
                          _persistEmployeeListViewPreferences();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<_EmployeeSortMode>(
                        initialValue: _employeeSortMode,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<_EmployeeSortMode>(
                            value: _EmployeeSortMode.nameAsc,
                            child: Text('Name A-Z'),
                          ),
                          DropdownMenuItem<_EmployeeSortMode>(
                            value: _EmployeeSortMode.nameDesc,
                            child: Text('Name Z-A'),
                          ),
                          DropdownMenuItem<_EmployeeSortMode>(
                            value: _EmployeeSortMode.skillCountDesc,
                            child: Text('Most Skills'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _employeeSortMode = value;
                          });
                          _persistEmployeeListViewPreferences();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _employeeSearchController.clear();
                        _employeeSearchQuery = '';
                        _selectedEmployeeFilterSkill = null;
                        _employeeSortMode = _EmployeeSortMode.nameAsc;
                      });
                      _persistEmployeeListViewPreferences();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ),
                if (_employees.isEmpty)
                  const Text('No employees added yet.')
                else if (visibleEmployees.isEmpty)
                  const Text('No employees match the current search/filter.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleEmployees.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final employee = visibleEmployees[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        title: Text(employee.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (employee.skills.isEmpty)
                                const Text('No skills assigned')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: employee.skills
                                      .map((skill) => Chip(label: Text(skill)))
                                      .toList(growable: false),
                                ),
                              const SizedBox(height: 6),
                              if (employee.licenses.isEmpty)
                                const Text('No licenses assigned')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: employee.licenses
                                      .map(
                                        (license) => Chip(
                                          label: Text(license),
                                          avatar: const Icon(
                                            Icons.verified_outlined,
                                            size: 16,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                            ],
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit Employee',
                              onPressed: () => _editEmployee(employee),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete Employee',
                              onPressed: () => _deleteEmployee(employee),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
