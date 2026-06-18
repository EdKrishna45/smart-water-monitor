import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String recoveryMethod;

  const OtpScreen({super.key, this.email = '', this.recoveryMethod = 'email'});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = Enter Email/Phone, 2 = Verify OTP, 3 = Reset Password, 4 = Success
  String? _sentOtp;
  bool _isLoading = false;
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final contact = _emailController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your contact details'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final otpResult = await authProvider.sendRecoveryOtp(contact);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (otpResult != null) {
      if (otpResult == 'firebase_sent') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase reset link successfully sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
      } else {
        // Mock OTP generated successfully
        _sentOtp = otpResult;
        setState(() => _step = 2);
        
        // Show the simulated OTP in a gorgeous dialog
        showDialog(
          context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.sms_failed, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text('SMS/Email Gateway Sim', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A simulated verification message was sent to $contact.', style: GoogleFonts.inter()),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        'Your OTP is: $_sentOtp',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Enter Code', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to send OTP.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _verifyOtp() {
    final entered = _otpController.text.trim();
    if (entered == _sentOtp) {
      setState(() => _step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code. Please try again.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _resetPassword() async {
    final password = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim(), password);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      setState(() => _step = 4);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Password reset failed.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2885E5);

    String title = 'Recover Account';
    String subtitle = '';
    if (_step == 1) {
      subtitle = widget.recoveryMethod == 'phone' 
          ? 'Enter your registered phone number' 
          : 'Enter your registered email address';
    } else if (_step == 2) {
      subtitle = 'Enter the 6-digit code we sent you';
    } else if (_step == 3) {
      subtitle = 'Set a strong new password';
    } else if (_step == 4) {
      title = 'Password Reset! 🎉';
      subtitle = 'Your password has been updated successfully';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5FB),
      body: Column(
        children: [
          // Header Section with Wave
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * (_step == 4 ? 0.30 : 0.35),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF155DB0), primaryColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Back Button
                      if (_step < 4)
                        GestureDetector(
                          onTap: () {
                            if (_step > 1) {
                              setState(() => _step--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        )
                      else
                        const SizedBox(height: 34), // Spacing when no back button
                        
                      const Spacer(),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: _step == 4 ? 26 : 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Step Indicator
                      if (_step < 4)
                        Row(
                          children: [
                            _buildIndicator(1),
                            const SizedBox(width: 6),
                            _buildIndicator(2),
                            const SizedBox(width: 6),
                            _buildIndicator(3),
                            const SizedBox(width: 6),
                            _buildIndicator(4),
                          ],
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Body Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  
                  // STEP 1: Enter Email/Phone
                  if (_step == 1) ...[
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black87),
                      keyboardType: widget.recoveryMethod == 'phone' ? TextInputType.phone : TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: widget.recoveryMethod == 'phone' ? 'Phone Number' : 'Email Address',
                        icon: widget.recoveryMethod == 'phone' ? Icons.phone_outlined : Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      text: 'Send Code',
                      onPressed: _isLoading ? null : _sendOtp,
                    ),
                  ],

                  // STEP 2: Verify OTP
                  if (_step == 2) ...[
                    TextFormField(
                      controller: _otpController,
                      style: const TextStyle(color: Colors.black87),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration(label: 'Verification Code', icon: Icons.pin_outlined).copyWith(
                        hintText: '000000',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPrimaryButton(
                      text: 'Verify Code',
                      onPressed: _verifyOtp,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _sendOtp,
                      child: Text('Resend Code', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    )
                  ],

                  // STEP 3: Create New Password
                  if (_step == 3) ...[
                    // Success Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Identity verified! Set your new password below.',
                              style: GoogleFonts.inter(color: Colors.green[700], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // New Password
                    TextFormField(
                      controller: _newPasswordController,
                      style: const TextStyle(color: Colors.black87),
                      obscureText: _obscurePassword1,
                      decoration: _inputDecoration(
                        label: 'New password (min. 6 chars)',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword1 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.blueGrey[300]),
                          onPressed: () => setState(() => _obscurePassword1 = !_obscurePassword1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.black87),
                      obscureText: _obscurePassword2,
                      decoration: _inputDecoration(
                        label: 'Confirm new password',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword2 ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.blueGrey[300]),
                          onPressed: () => setState(() => _obscurePassword2 = !_obscurePassword2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildPrimaryButton(
                      text: 'Reset Password',
                      onPressed: _isLoading ? null : _resetPassword,
                    ),
                  ],

                  // STEP 4: Success Screen
                  if (_step == 4) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 54),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Password Updated!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your password has been successfully reset.\nYou can now sign in with your new password.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPrimaryButton(
                      text: 'Back to Sign In',
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int flowStep) {
    bool isActive = (_step + 1) == flowStep;
    return Container(
      width: isActive ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: label,
      hintStyle: GoogleFonts.inter(color: Colors.blueGrey[300]),
      prefixIcon: Icon(icon, color: Colors.blue[400]),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2885E5),
        disabledBackgroundColor: const Color(0xFF2885E5).withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: _isLoading && text != 'Back to Sign In'
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
