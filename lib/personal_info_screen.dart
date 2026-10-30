import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'country_list.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key, this.countryLoader});

  final CountryLoader? countryLoader;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const double _defaultAge = 25;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  double _age = _defaultAge;
  List<String> _countries = const [];
  String? _selectedCountry;
  String? _countryLoadError;
  bool _isLoadingUserData = true;
  bool _isLoadingCountries = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final preferences = await SharedPreferences.getInstance();
    final savedName = preferences.getString('name') ?? '';
    final savedUsername = preferences.getString('username') ?? '';
    final savedAge = preferences.getDouble('age') ?? _defaultAge;
    final savedCountry = preferences.getString('country')?.trim();

    if (!mounted) return;
    setState(() {
      _nameController.text = savedName;
      _usernameController.text = savedUsername;
      _age = savedAge.clamp(18, 100).toDouble();
      _selectedCountry = savedCountry == null || savedCountry.isEmpty
          ? null
          : savedCountry;
      _isLoadingUserData = false;
    });

    await _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _countryLoadError = null;
    });

    try {
      final loader = widget.countryLoader ?? CountryService().fetchCountries;
      final loadedCountries = await loader();
      if (!mounted) return;

      final countries = <String>{...loadedCountries};
      if (_selectedCountry != null) countries.add(_selectedCountry!);
      final sortedCountries = countries.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _countries = sortedCountries;
        _isLoadingCountries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countryLoadError = 'Unable to load countries';
        _isLoadingCountries = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('name', _nameController.text.trim());
    await preferences.setString('username', _usernameController.text.trim());
    await preferences.setDouble('age', _age);
    if (_selectedCountry != null) {
      await preferences.setString('country', _selectedCountry!);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('personalInfoScreen'),
      appBar: AppBar(title: const Text('Personal Info')),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Profile details',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Update the personal information saved on this device.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            key: const Key('personalInfoName'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('personalInfoUsername'),
                            controller: _usernameController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Age: ${_age.round()}',
                            key: const Key('personalInfoAgeLabel'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Slider(
                            key: const Key('personalInfoAgeSlider'),
                            min: 18,
                            max: 100,
                            divisions: 82,
                            value: _age,
                            label: _age.round().toString(),
                            onChanged: (value) => setState(() => _age = value),
                          ),
                          const SizedBox(height: 12),
                          _buildCountryField(),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            key: const Key('savePersonalInfoButton'),
                            onPressed:
                                _isSaving ||
                                    _isLoadingCountries ||
                                    (_countryLoadError != null &&
                                        _selectedCountry == null)
                                ? null
                                : _saveUserData,
                            icon: _isSaving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCountryField() {
    if (_isLoadingCountries) {
      return const ListTile(
        key: Key('personalInfoCountryLoading'),
        contentPadding: EdgeInsets.zero,
        leading: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading countries...'),
      );
    }

    if (_countryLoadError != null) {
      return Card(
        key: const Key('personalInfoCountryError'),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _countryLoadError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedCountry != null) ...[
                const SizedBox(height: 4),
                Text('Current country: $_selectedCountry'),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('retryPersonalInfoCountriesButton'),
                onPressed: _loadCountries,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: const Key('personalInfoCountry'),
      initialValue: _selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public),
      ),
      hint: const Text('Select your country'),
      items: _countries
          .map(
            (country) => DropdownMenuItem<String>(
              value: country,
              child: Text(country, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCountry = value),
    );
  }
}
