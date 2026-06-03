import 'package:flutter/material.dart';

class IdCardBenefitsContent extends StatefulWidget {
  const IdCardBenefitsContent({super.key});

  @override
  State<IdCardBenefitsContent> createState() => _IdCardBenefitsContentState();
}

class _IdCardBenefitsContentState extends State<IdCardBenefitsContent> {
  bool _isTamil = true;

  final List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.warning_amber_rounded,
      'en': {
        'title': 'Emergency Response Support',
        'desc': 'Provides immediate identification and quick support for safety and crisis management.',
      },
      'ta': {
        'title': 'அவசர கால உதவி ஆதரவு',
        'desc': 'பாதுகாப்பு மற்றும் பேரிடர் மேலாண்மைக்கு உடனடி அடையாளத்தையும் விரைவான ஆதரவையும் வழங்குகிறது.',
      }
    },
    {
      'icon': Icons.fingerprint,
      'en': {
        'title': 'Unified ID Card System',
        'desc': 'Streamlines identification and connectivity across the entire organization or community.',
      },
      'ta': {
        'title': 'ஒருங்கிணைந்த அடையாள அட்டை',
        'desc': 'ஒட்டுமொத்த சமூகம் மற்றும் அமைப்பிற்குள் தடையற்ற அடையாளப்படுத்தலையும் இணைப்பையும் எளிதாக்குகிறது.',
      }
    },
    {
      'icon': Icons.qr_code_2,
      'en': {
        'title': 'QR Code with Family Details',
        'desc': 'Advanced digital integration for quick and secure access to essential kinship information.',
      },
      'ta': {
        'title': 'குடும்ப விவரங்களுடன் QR குறியீடு',
        'desc': 'அத்தியாவசிய குடும்ப விவரங்களை விரைவாகவும் பாதுகாப்பாகவும் அணுக உதவும் மேம்பட்ட டிஜிட்டல் ஒருங்கிணைப்பு.',
      }
    },
    {
      'icon': Icons.local_offer_outlined,
      'en': {
        'title': 'Business Offers & Discounts',
        'desc': 'Acts as a premium membership pass for exclusive economic benefits and discounts.',
      },
      'ta': {
        'title': 'பிரத்யேக வணிக சலுகைகள் & தள்ளுபடிகள்',
        'desc': 'பிரத்யேக பொருளாதார நன்மைகள் மற்றும் தள்ளுபடிகளைப் பெற ஒரு பிரீமியம் உறுப்பினர் அட்டையாகச் செயல்படுகிறது.',
      }
    },

    {
      'icon': Icons.local_fire_department_outlined,
      'en': {
        'title': 'Temple Pooja Initiatives',
        'desc': 'Facilitates seamless participation, priority bookings, and recognition in traditional community activities.',
      },
      'ta': {
        'title': 'கோயில் பூஜை வழிபாட்டு முன்னுரிமை',
        'desc': 'பாரம்பரிய சமூக மற்றும் ஆன்மீக வழிபாடுகளில் தடையற்ற பங்கேற்பு மற்றும் முன்னுரிமையை வழங்குகிறது.',
      }
    },
    {
      'icon': Icons.campaign_outlined,
      'en': {
        'title': 'Business Promotion Tools',
        'desc': 'Serves as an influential tool for networking, professional visibility, and business growth.',
      },
      'ta': {
        'title': 'வணிக மேம்பாட்டு வாய்ப்புகள்',
        'desc': 'சமூக உறவுகள், தொழில்முறை அங்கீகாரம் மற்றும் வணிக வளர்ச்சிக்கு ஒரு சிறந்த கருவியாக அமைகிறது.',
      }
    },
    {
      'icon': Icons.grass,
      'en': {
        'title': 'Agricultural Resources & Support',
        'desc': 'Connects agrarian members directly to sector-specific modern resources, guidance, and aid.',
      },
      'ta': {
        'title': 'விவசாய ஆதரவு மற்றும் வழிகாட்டுதல்',
        'desc': 'விவசாயப் பெருமக்களை நேரடியாக நவீன விவசாய வளங்கள், வழிகாட்டுதல் மற்றும் உதவிகளுடன் இணைக்கிறது.',
      }
    },
    {
      'icon': Icons.school_outlined,
      'en': {
        'title': 'Education Support & Career Guidance',
        'desc': 'Identifies students and young professionals for targeted academic scholarships and mentorship.',
      },
      'ta': {
        'title': 'கல்வி உதவி & தொழில் வழிகாட்டுதல்',
        'desc': 'மாணவச் செல்வங்கள் மற்றும் இளம் பட்டதாரிகளை அடையாளம் கண்டு பிரத்யேக கல்வி உதவித்தொகை மற்றும் வழிகாட்டுதலை வழங்குகிறது.',
      }
    },
    {
      'icon': Icons.work_outline,
      'en': {
        'title': 'Employment Assistance & Support',
        'desc': 'Validates member status for community-driven job placements, references, and assistance.',
      },
      'ta': {
        'title': 'வேலைவாய்ப்பு ஆதரவு மற்றும் வழிகாட்டல்',
        'desc': 'சமூக அளவிலான வேலைவாய்ப்பு, பரிந்துரைகள் மற்றும் உதவிக்கு உறுப்பினரின் தகுதியை உறுதிப்படுத்துகிறது.',
      }
    },
    {
      'icon': Icons.health_and_safety_outlined,
      'en': {
        'title': 'Group Insurance Benefits',
        'desc': 'Links the cardholder to collective medical security, health benefits, and life cover.',
      },
      'ta': {
        'title': 'குழு காப்பீட்டுத் திட்டம்',
        'desc': 'அட்டைதாரர்களை கூட்டு மருத்துவப் பாதுகாப்பு, சுகாதார நன்மைகள் மற்றும் ஆயுள் காப்பீட்டுடன் இணைக்கிறது.',
      }
    },
    {
      'icon': Icons.water_drop_outlined,
      'en': {
        'title': 'Water Welfare & Ecological Renewal',
        'desc': 'Directs contributions and volunteer efforts to community-driven pond renovations and water body revival.',
      },
      'ta': {
        'title': 'நீர்வழி தடம் & குளம் சீரமைப்பு',
        'desc': 'சமூக அளவிலான குளம் சீரமைப்பு மற்றும் நீர்நிலை மீட்புப் பணிகளுக்கு பங்களிப்புகளையும் தன்னார்வ முயற்சிகளையும் வழிநடத்துகிறது.',
      }
    }
  ];

  @override
  Widget build(BuildContext context) {
    final langKey = _isTamil ? 'ta' : 'en';

    return Stack(
      children: [
        // Background watermark image
        Positioned.fill(
          child: Opacity(
            opacity: 0.15, // Increased opacity so it is visible
            child: Image.asset(
              'assets/images/perumal kovil.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Language Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 40, height: 2, color: const Color(0xFFC49A3C)),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _isTamil ? 'பிரத்தியேக சலுகைகள்' : 'EXCLUSIVE PRIVILEGES',
                                style: const TextStyle(
                                  color: const Color(0xFFC49A3C),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isTamil ? 'அடையாள அட்டை நன்மைகள்' : 'Advantages of the ID Card',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600 ? 42 : 28, // Responsive font size
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D1B18),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.language, size: 18),
                    label: Text(_isTamil ? 'English' : 'தமிழ்', style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D1B18),
                      side: BorderSide(color: const Color(0xFFC49A3C).withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _isTamil = !_isTamil;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Hero Section (Text + Flip Card)
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 900;
                  
                  Widget textSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTamil 
                          ? 'பூந்துறை காடை அடையாள அட்டை என்பது வெறும் அடையாளம் மட்டுமல்ல; இது கூட்டு பாதுகாப்பு, சமூக செழிப்பு மற்றும் பண்பாட்டு பாதுகாப்பிற்கான ஒரு நுழைவாயிலாகும். நமது உறுப்பினர்களை ஆதரிப்பதற்காக வடிவமைக்கப்பட்ட பன்னிரண்டு முக்கிய நன்மைகளை இங்கே ஆராயுங்கள்.' 
                          : 'The Poondurai Kaadai ID Card is more than an identity; it is a gateway to collective security, community prosperity, and cultural preservation. Explore the twelve core benefits designed to support and elevate our members.',
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),

                    ],
                  );

                  Widget cardSection = Column(
                    children: [
                      const _FlipCard(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _isTamil ? 'அட்டையைத் திருப்ப அதன் மீது கர்சரை வைக்கவும் (அல்லது) அழுத்தவும்' : 'HOVER OR CLICK TO VIEW BACK',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 3, child: textSection),
                        const SizedBox(width: 48),
                        Expanded(flex: 2, child: Center(child: cardSection)),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textSection,
                        const SizedBox(height: 48),
                        Center(child: cardSection),
                      ],
                    );
                  }
                },
              ),
              
              const SizedBox(height: 64),
              
              // Grid of benefits
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 280, // Increased height to prevent text overflow on mobile
                    ),
                    itemCount: _benefits.length,
                    itemBuilder: (context, index) {
                      final item = _benefits[index];
                      final data = item[langKey] as Map<String, dynamic>;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC49A3C).withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [const Color(0xFF8B1D1D), const Color(0xFF2D1B18)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B1D1D).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade300,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              data['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D1B18),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['desc'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 48),


              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard();

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    // Use pi to rotate 180 degrees
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: _toggleCard, // Keep tap for mobile devices
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * 3.1415926535897932; // pi
            bool isFrontVisible = angle <= 3.1415926535897932 / 2;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFrontVisible 
                ? _buildCardSide('assets/images/id card front.jpeg')
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.1415926535897932), // pi
                    alignment: Alignment.center,
                    child: _buildCardSide('assets/images/id card back.jpeg'),
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardSide(String imagePath) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D1B18).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
