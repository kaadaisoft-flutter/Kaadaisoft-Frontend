import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B18), // Dark top brand background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, isMobile ? 36 : 60, 16, isMobile ? 65 : 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B18), Color(0xFF1E100E)],
                ),
              ),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      label: const Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 28 : 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Poondurai Kaadai Kulam Community Platform & Mobile Application',
                    style: TextStyle(
                      color: const Color(0xFFC5A028),
                      fontSize: isMobile ? 14 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal data, privacy, and community security are our highest priorities.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: isMobile ? 12.5 : 14.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Main White Content Container
            Transform.translate(
              offset: const Offset(0, -45),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 960),
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: EdgeInsets.all(isMobile ? 18 : 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Last Updated Pill
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                            ),
                            child: const Text(
                              'EFFECTIVE DATE: NOVEMBER 04, 2026',
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Intro Highlight Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        'This Privacy Policy applies to the "Poondurai Kaadai Kulam" mobile application, website, and related digital services operated for community members. We are committed to transparency, data minimization, and protecting the sensitive community records entrusted to us in compliance with Google Play Developer Program Policies and applicable data protection regulations.',
                        style: TextStyle(
                          fontSize: isMobile ? 13.5 : 14.5,
                          color: const Color(0xFF374151),
                          height: 1.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 1. Information We Collect
                    _buildSectionTitle('1. Information We Collect', isMobile),
                    _buildSectionText(
                      'To authenticate members, verify heritage lineages, generate digital ID cards, and coordinate community welfare, we collect only necessary personal and demographic details directly provided by you or your authorized family head:',
                    ),
                    const SizedBox(height: 14),
                    _buildHighlightBox(
                      title: 'Categories of Data Collected:',
                      isMobile: isMobile,
                      children: [
                        _buildBulletItem(
                          'Personal Identification',
                          'Full legal name, gender, date of birth, marital status, blood group, and passport-size profile photograph.',
                        ),
                        _buildBulletItem(
                          'Community Lineage & Heritage Details',
                          'Kulam (Poondurai Kaadai Kulam), Valuvu, Thottam, and family relationship hierarchy (e.g., Head, Spouse, Children, Parents).',
                        ),
                        _buildBulletItem(
                          'Contact & Residential Addresses',
                          'Mobile phone number, WhatsApp contact number, current and permanent address (Door number, street name, village, panchayat, taluk, district, state, and pin code/NRI city).',
                        ),
                        _buildBulletItem(
                          'Verification Documents',
                          'Optional community certificate or verification documents submitted solely to validate community membership.',
                        ),
                        _buildBulletItem(
                          'Professional Directory Details (Optional)',
                          'Specialization, workplace, qualifications, and years of experience for members opting to publish their professional profile in the community Doctors or Lawyers directory.',
                        ),
                      ],
                    ),

                    // 2. Device Permissions & Specific Purpose
                    _buildSectionTitle('2. Device Permissions & How We Use Them', isMobile),
                    _buildSectionText(
                      'Our mobile application requests specific device permissions strictly when needed to deliver core community features. We never access your device sensors or private data without your explicit consent:',
                    ),
                    const SizedBox(height: 14),
                    _buildPermissionCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera Permission (CAMERA)',
                      purpose:
                          'Used strictly for real-time QR code scanning to verify digital Member ID cards, record community meeting attendance, and optionally capture a new profile photo directly from your camera.',
                    ),
                    _buildPermissionCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Photos & Storage Permission (READ_MEDIA_IMAGES / STORAGE)',
                      purpose:
                          'Used solely to allow you to select and upload your profile picture or community verification certificates from your gallery.',
                    ),
                    _buildPermissionCard(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications Permission (POST_NOTIFICATIONS)',
                      purpose:
                          'Used to deliver urgent community notices, emergency blood donation calls, event announcements, and membership approval updates.',
                    ),
                    _buildPermissionCard(
                      icon: Icons.wifi,
                      title: 'Network & Internet Access (INTERNET / ACCESS_NETWORK_STATE)',
                      purpose:
                          'Used to securely transmit and synchronize your encrypted membership data with our protected backend servers over HTTPS.',
                    ),

                    // 3. How We Use Your Information
                    _buildSectionTitle('3. Purpose of Processing Personal Data', isMobile),
                    _buildSectionText(
                      'Your data is processed strictly for authentic community administration, non-profit welfare, and communication purposes:',
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleBullet('Generating unique digital Member IDs, Permanent Family IDs, and QR-enabled Privilege ID cards.'),
                    _buildSimpleBullet('Maintaining an authentic directory of verified community families across districts and taluks.'),
                    _buildSimpleBullet('Connecting emergency blood donors with patients in urgent medical need via blood group listings.'),
                    _buildSimpleBullet('Facilitating village and taluk committee coordinators in organizing community meetings and welfare events.'),
                    _buildSimpleBullet('Allowing members to view authorized professional listings (Doctors and Lawyers) within the community.'),
                    _buildSimpleBullet('Preventing fraudulent registrations and maintaining institutional trust integrity.'),

                    // 4. Data Sharing & Third-Party Disclosure
                    _buildSectionTitle('4. Data Sharing & Third-Party Disclosure', isMobile),
                    _buildSectionText(
                      'We have a strict non-commercial policy regarding personal data:\n\n'
                      '• We DO NOT sell, rent, monetize, or trade any personal information to commercial third parties or advertising brokers.\n'
                      '• We DO NOT embed any third-party behavioral advertising or tracking SDKs.\n'
                      '• Third-Party Service Providers: We utilize Google Firebase Cloud Messaging solely to transmit secure push notifications to your registered Android device. No sensitive identity records are transferred to Firebase.\n'
                      '• Internal Access Control: Full administrative records are restricted to authenticated admins, and local committee coordinators can only view verified member records within their assigned geographic jurisdiction.',
                    ),

                    // 5. Data Security & Storage
                    _buildSectionTitle('5. Data Security Safeguards', isMobile),
                    _buildSectionText(
                      'We apply industry-standard technical and organizational security controls to protect your data:\n\n'
                      '• Encrypted Data in Transit: All communications between the app and server are protected using industry-standard Transport Layer Security (TLS 1.2/1.3 / HTTPS).\n'
                      '• Role-Based Access Controls (RBAC): Multi-tier permission levels (Admin, Manager, Coordinator, Member) ensure that sensitive information is accessible only on a verified, need-to-know basis.\n'
                      '• Secure Passwords: Passwords are protected using salted cryptographic hashing (bcrypt) and are never stored in plaintext.',
                    ),

                    // 6. User Rights, Account Deletion & Data Retention
                    _buildSectionTitle('6. Account Deletion & Your Data Rights (Google Play Compliant)', isMobile),
                    _buildSectionText(
                      'We respect your rights regarding your personal information. You have the right to access, review, modify, or permanently delete your account and associated personal data at any time.',
                    ),
                    const SizedBox(height: 14),
                    // Deletion Box (Fixed overflow with Expanded)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_forever, color: Color(0xFF16A34A), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'How to Request Account & Data Deletion:',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '1. In-App Option: Log in to your account, navigate to "My Details", select "Settings / Edit Profile", and tap "Request Account Deletion".\n\n'
                            '2. Email Request Option: Send an email from your registered email address or mobile number to poonduraikaadaikulam2026@gmail.com with the subject line "Request Account Deletion" along with your Family Member ID.\n\n'
                            'Timeline: Upon receiving your verified deletion request, your account credentials, profile photograph, documents, and personal details will be permanently erased from our active database within 30 days, except where retention is strictly required by statutory Indian laws.',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: const Color(0xFF14532D),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 7. Children's Privacy
                    _buildSectionTitle('7. Children\'s Privacy', isMobile),
                    _buildSectionText(
                      'The Poondurai Kaadai Kulam application is designed for adult community members and family heads. We do not knowingly collect personal information directly from children under 13 years of age. Details of minor family dependents are recorded exclusively by their verified adult parents/guardians as part of the unified family registry.',
                    ),

                    // 8. Policy Updates
                    _buildSectionTitle('8. Policy Updates & Notifications', isMobile),
                    _buildSectionText(
                      'We may update this Privacy Policy periodically to reflect enhancements in our services, security practices, or legal requirements. Any revisions will be published directly within the mobile application and on our website with a revised "Effective Date".',
                    ),

                    // 9. Contact & Grievance Officer
                    _buildSectionTitle('9. Grievance Officer & Contact Information', isMobile),
                    _buildSectionText(
                      'For any questions, privacy concerns, data modification requests, or to exercise your rights under Indian IT and Digital Personal Data Protection laws, please contact our designated administrator:',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Poondurai Kaadai Kulam Administration & Trust',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF5D1712)),
                          ),
                          const SizedBox(height: 10),
                          _buildContactRow(Icons.email_outlined, 'Official Email: poonduraikaadaikulam2026@gmail.com'),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.location_on_outlined, 'Location: Erode, Tamil Nadu, India'),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.access_time_outlined, 'Support Hours: Monday to Saturday (9:00 AM - 6:00 PM IST)'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                '© 2026 Poondurai Kaadai Kulam. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 26 : 34, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: isMobile ? 18 : 22,
            decoration: BoxDecoration(
              color: const Color(0xFFC49A3C),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D1B18),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF4B5563),
        height: 1.65,
      ),
    );
  }

  Widget _buildHighlightBox({required String title, required List<Widget> children, required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8D6E18),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPermissionCard({required IconData icon, required String title, required String purpose}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D1712).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF5D1712), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purpose,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF8D6E18)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.6),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFC49A3C)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: const Color(0xFF5D1712)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
      ],
    );
  }
}
