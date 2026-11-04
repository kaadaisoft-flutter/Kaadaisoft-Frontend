import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../widgets/custom_dialog.dart';

class LawyerProfilePage extends StatelessWidget {
  final Map<String, dynamic> lawyer;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onBack;

  const LawyerProfilePage({
    super.key,
    required this.lawyer,
    this.canManage = false,
    this.onEdit,
    this.onBack,
  });

  // Theme Colors
  static const Color primaryMaroon = Color(0xFF5D1712);
  static const Color darkSidebarBrown = Color(0xFF2D1B18);
  static const Color logoGold = Color(0xFFC49A3C);
  static const Color lightGold = Color(0xFFFEF3C7);
  static const Color legalAmber = Color(0xFFB45309);
  static const Color legalAmberLight = Color(0xFFFFFBEB);
  static const Color legalAmberBorder = Color(0xFFFDE68A);




  Future<void> _sendEmail(BuildContext context, String email, String name) async {
    final uri = Uri.parse('mailto:$email?subject=Legal Enquiry from Poondurai Kaadaikulam Member');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: email));
        showStatusDialog(
          context,
          title: 'Email Copied',
          message: 'Email $email copied to clipboard.',
          type: DialogType.info,
        );
      }
    }
  }

  void _copyAllDetails(BuildContext context, bool isTamil) {
    final name = lawyer['name'] ?? '';
    final spec = lawyer['specialization'] ?? '';
    final qual = lawyer['qualifications'] ?? '';
    final work = lawyer['workplace'] ?? '';
    final native = lawyer['native_place'] ?? '';
    final phone = lawyer['phone'] ?? '';
    final email = lawyer['email'] ?? '';

    final text = '''
Adv. $name
${isTamil ? "சிறப்பு வழக்கறிஞர் துறை" : "Legal Specialization"}: $spec
${isTamil ? "சட்டக் கல்வித் தகுதிகள்" : "Law Qualifications"}: $qual
${isTamil ? "வழக்கறிஞர் அலுவலகம் / பணிவிடம்" : "Chambers / Workplace"}: $work
${isTamil ? "சொந்த ஊர்" : "Native Place"}: $native
${phone.isNotEmpty ? "${isTamil ? "தொலைபேசி" : "Phone"}: $phone" : ""}
${email.isNotEmpty ? "${isTamil ? "மின்னஞ்சல்" : "Email"}: $email" : ""}
''';

    Clipboard.setData(ClipboardData(text: text.trim()));
    showStatusDialog(
      context,
      title: isTamil ? 'விவரங்கள் நகலெடுக்கப்பட்டது' : 'Profile Copied',
      message: isTamil
          ? 'வழக்கறிஞரின் விவரங்கள் கிளிப்போர்டில் நகலெடுக்கப்பட்டது.'
          : 'Lawyer profile details copied to clipboard.',
      type: DialogType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = Provider.of<LocaleProvider>(context).locale.languageCode == 'ta';
    final isMobile = MediaQuery.of(context).size.width < 768;

    final name = lawyer['name']?.toString() ?? 'Advocate';
    final specialization = lawyer['specialization']?.toString() ?? (isTamil ? 'வழக்கறிஞர்' : 'Advocate / Legal Practitioner');
    final qualifications = lawyer['qualifications']?.toString();
    final workplace = lawyer['workplace']?.toString();
    final experience = lawyer['experience_years'];
    final nativePlace = lawyer['native_place']?.toString();
    final birthPlace = lawyer['birth_place']?.toString();
    final currentLocation = lawyer['current_location']?.toString();
    final phone = lawyer['phone']?.toString();
    final email = lawyer['email']?.toString();
    final dob = lawyer['dob']?.toString();
    final bio = lawyer['bio_summary']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: darkSidebarBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(onBack != null ? Icons.close : Icons.arrow_back),
          tooltip: isTamil ? (onBack != null ? 'மூடு' : 'பின்னே செல்') : (onBack != null ? 'Close' : 'Back'),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: legalAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: logoGold, width: 1.2),
              ),
              child: const Icon(Icons.gavel_rounded, size: 16, color: logoGold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isTamil ? 'நீதியின் குரல்' : 'Voice of Justice (Lawyer Profile)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: isTamil ? 'விவரங்களை நகலெடு' : 'Copy Details',
            onPressed: () => _copyAllDetails(context, isTamil),
          ),
          if (canManage && onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: isTamil ? 'சுயவிவரத்தைத் திருத்து' : 'Edit Profile',
              onPressed: onEdit,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Lawyer Hero Banner
                _buildLawyerHero(context, isTamil, isMobile, name, specialization, experience, workplace),
                const SizedBox(height: 20),


                // 3. Main Info Grid (2 columns on desktop, 1 on mobile)
                if (isMobile) ...[
                  _buildLegalDetailsCard(isTamil, qualifications, workplace, specialization, experience),
                  const SizedBox(height: 16),
                  _buildRootsCard(isTamil, nativePlace, birthPlace, currentLocation, dob),
                  const SizedBox(height: 16),
                  _buildContactCard(context, isTamil, phone, email),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildLegalDetailsCard(isTamil, qualifications, workplace, specialization, experience),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildRootsCard(isTamil, nativePlace, birthPlace, currentLocation, dob),
                            const SizedBox(height: 16),
                            _buildContactCard(context, isTamil, phone, email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // 4. Bio / Profile Summary (Full Width)
                if (bio != null && bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildBioCard(isTamil, bio),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerHero(
    BuildContext context,
    bool isTamil,
    bool isMobile,
    String name,
    String specialization,
    dynamic experience,
    String? workplace,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkSidebarBrown, Color(0xFF4A1512), primaryMaroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkSidebarBrown.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: logoGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isMobile ? 32 : 40,
                  backgroundColor: const Color(0xFF2D1B18),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: logoGold,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: Lawyer
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: legalAmberLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: legalAmberBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.balance, size: 13, color: legalAmber),
                              const SizedBox(width: 4),
                              Text(
                                isTamil ? 'நீதியின் குரல் • வழக்கறிஞர்' : 'Voice of Justice • Advocate',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: legalAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (experience != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: lightGold,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              '$experience+ ${isTamil ? "ஆண்டுகள் சட்டப்பணி" : "Yrs Practice"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Lawyer Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 22, color: logoGold),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Specialization
                    Text(
                      specialization,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFEF3C7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (workplace != null && workplace.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              workplace,
                              style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildLegalDetailsCard(
    bool isTamil,
    String? qualifications,
    String? workplace,
    String specialization,
    dynamic experience,
  ) {
    return _buildSectionContainer(
      icon: Icons.gavel_outlined,
      iconColor: legalAmber,
      title: isTamil ? 'சட்டப்பணி & கல்வித் தகுதிகள்' : 'Legal Practice & Qualifications',
      children: [
        _buildInfoTile(
          icon: Icons.school_outlined,
          label: isTamil ? 'சட்டக் கல்வி & பட்டங்கள்' : 'Law Degrees & Academic Qualifications',
          value: qualifications,
          highlight: true,
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildInfoTile(
          icon: Icons.account_balance_outlined,
          label: isTamil ? 'நீதிமன்றம் / சட்ட அலுவலகம் / பணிவிடம்' : 'Chamber / Courts / Law Practice',
          value: workplace,
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildInfoTile(
          icon: Icons.balance_outlined,
          label: isTamil ? 'சிறப்பு சட்டத் துறை' : 'Areas of Legal Practice',
          value: specialization,
        ),
        if (experience != null) ...[
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoTile(
            icon: Icons.history_edu_outlined,
            label: isTamil ? 'சட்டப்பணி அனுபவம்' : 'Years at the Bar',
            value: '$experience ${isTamil ? "ஆண்டுகள்" : "Years"}',
          ),
        ],
      ],
    );
  }

  Widget _buildRootsCard(
    bool isTamil,
    String? nativePlace,
    String? birthPlace,
    String? currentLocation,
    String? dob,
  ) {
    return _buildSectionContainer(
      icon: Icons.home_work_outlined,
      iconColor: primaryMaroon,
      title: isTamil ? 'சொந்த ஊர் & இருப்பிடம்' : 'Ancestral Roots & Location',
      children: [
        _buildInfoTile(
          icon: Icons.home_outlined,
          label: isTamil ? 'சொந்த ஊர் (Native Place)' : 'Native Place',
          value: nativePlace,
          highlight: true,
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildInfoTile(
          icon: Icons.location_city_outlined,
          label: isTamil ? 'பிறந்த இடம்' : 'Birth Place',
          value: birthPlace,
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildInfoTile(
          icon: Icons.place_outlined,
          label: isTamil ? 'தற்போதைய வசிப்பிடம் / அலுவலகம்' : 'Current Residence / Location',
          value: currentLocation,
        ),
        if (dob != null && dob.isNotEmpty) ...[
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoTile(
            icon: Icons.cake_outlined,
            label: isTamil ? 'பிறந்த தேதி' : 'Date of Birth',
            value: dob.contains('-') ? dob.split('-').reversed.join('/') : dob,
          ),
        ],
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    bool isTamil,
    String? phone,
    String? email,
  ) {
    return _buildSectionContainer(
      icon: Icons.contact_phone_outlined,
      iconColor: logoGold,
      title: isTamil ? 'தொடர்பு விவரங்கள்' : 'Contact Details',
      children: [
        if (phone != null && phone.isNotEmpty) ...[
          _buildInfoTile(
            icon: Icons.phone_android_outlined,
            label: isTamil ? 'தொலைபேசி எண்' : 'Mobile Phone',
            value: phone,
          ),
        ],
        if (email != null && email.isNotEmpty) ...[
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          InkWell(
            onTap: () => _sendEmail(context, email, lawyer['name'] ?? ''),
            borderRadius: BorderRadius.circular(8),
            child: _buildInfoTile(
              icon: Icons.email_outlined,
              label: isTamil ? 'மின்னஞ்சல் முகவரி' : 'Email Address',
              value: email,
              trailing: const Icon(Icons.arrow_outward, size: 14, color: legalAmber),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBioCard(bool isTamil, String bio) {
    return _buildSectionContainer(
      icon: Icons.notes_outlined,
      iconColor: legalAmber,
      title: isTamil ? 'சட்டப்பணி சாதனை & சுயவிவர சுருக்கம்' : 'Legal Career Overview & Profile Summary',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1E6D0)),
          ),
          child: Text(
            bio,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF2D1B18),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContainer({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkSidebarBrown,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String? value,
    bool highlight = false,
    Widget? trailing,
  }) {
    final displayValue = (value != null && value.trim().isNotEmpty) ? value : '—';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? darkSidebarBrown : const Color(0xFF334155),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
