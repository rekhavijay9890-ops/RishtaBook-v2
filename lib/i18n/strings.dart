import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_controller.dart';

/// hi/en copy keyed by a dotted key. Missing keys fall back to the key
/// itself so a typo shows up as visible junk in the UI instead of crashing.
const Map<String, Map<String, String>> _dict = {
  // ── App / nav ──
  'app.name':            {'hi': 'रिश्ताबुक', 'en': 'RishtaBook'},
  'app.tagline':         {'hi': 'अपना सही जीवनसाथी खोजें', 'en': 'Find your perfect match'},
  'nav.home':            {'hi': 'मुखपृष्ठ', 'en': 'Home'},
  'nav.search':          {'hi': 'खोजें', 'en': 'Search'},
  'nav.interests':       {'hi': 'रुचियाँ', 'en': 'Interests'},
  'nav.chat':            {'hi': 'बातचीत', 'en': 'Chat'},
  'nav.profile':         {'hi': 'प्रोफ़ाइल', 'en': 'Profile'},

  // ── Common ──
  'common.viewAll':      {'hi': 'सभी देखें →', 'en': 'View all →'},
  'common.cancel':       {'hi': 'रद्द करें', 'en': 'Cancel'},
  'common.close':        {'hi': 'बंद करें', 'en': 'Close'},
  'common.accept':       {'hi': 'स्वीकार करें', 'en': 'Accept'},
  'common.reject':       {'hi': 'अस्वीकार करें', 'en': 'Reject'},
  'common.report':       {'hi': 'रिपोर्ट करें', 'en': 'Report'},
  'common.share':        {'hi': 'शेयर करें', 'en': 'Share'},
  'common.logout':       {'hi': 'लॉगआउट', 'en': 'Logout'},
  'common.edit':         {'hi': 'संपादित करें', 'en': 'Edit'},
  'common.save':         {'hi': 'सहेजें', 'en': 'Save'},
  'common.verified':     {'hi': '✓ सत्यापित', 'en': '✓ Verified'},
  'common.premium':      {'hi': '★ प्रीमियम', 'en': '★ Premium'},
  'common.viewProfile':  {'hi': 'प्रोफ़ाइल देखें', 'en': 'View Profile'},
  'common.sendInterest': {'hi': 'रुचि भेजें', 'en': 'Send Interest'},
  'common.sent':         {'hi': 'भेजा गया', 'en': 'Sent'},
  'common.error':        {'hi': 'कुछ गलत हो गया।', 'en': 'Something went wrong.'},
  'common.notAvailable': {'hi': 'उपलब्ध नहीं', 'en': 'Not available'},
  'common.language':     {'hi': 'हिन्दी', 'en': 'English'},

  // ── Home ──
  'home.searchHint':     {'hi': 'नाम, शहर, जाति से खोजें...', 'en': 'Search name, city, caste...'},
  'home.suggested':      {'hi': 'अनुशंसित रिश्ते', 'en': 'Suggested matches'},
  'home.filterBy':       {'hi': 'फ़िल्टर करें', 'en': 'Filter by'},
  'home.noProfiles':     {'hi': 'अभी तक कोई नई प्रोफ़ाइल नहीं है।', 'en': 'No profiles yet.'},
  'home.noMatch':        {'hi': 'इन फ़िल्टर से कोई प्रोफ़ाइल नहीं मिली।', 'en': 'No profiles match these filters.'},
  'home.wallet.remaining': {'hi': '≈ %d चैट शेष', 'en': '≈ %d chats remaining'},
  'home.addCredits':     {'hi': 'क्रेडिट जोड़ें +', 'en': 'Add credits +'},

  // ── Search ──
  'search.title':        {'hi': 'अपना जीवनसाथी खोजें', 'en': 'Find your match'},
  'search.filters':      {'hi': '⚙ फ़िल्टर', 'en': '⚙ Filters'},
  'search.hint':         {'hi': 'नाम, शहर, पेशे से खोजें...', 'en': 'Search name, city, profession...'},
  'search.found':        {'hi': '%d प्रोफ़ाइल मिलीं', 'en': '%d profiles found'},
  'search.addFilter':    {'hi': '+ फ़िल्टर', 'en': '+ Filter'},
  'search.hidden':       {'hi': 'प्रोफ़ाइल छुपी है', 'en': 'Profile hidden'},
  'search.unlockHint':   {'hi': 'क्रेडिट से अनलॉक करें', 'en': 'Unlock with credits'},
  'search.unlock':       {'hi': 'अनलॉक करें', 'en': 'Unlock'},

  // ── Interests ──
  'interests.title':     {'hi': 'रुचियाँ', 'en': 'Interests'},
  'interests.received':  {'hi': 'प्राप्त', 'en': 'Received'},
  'interests.sent':      {'hi': 'भेजी गई', 'en': 'Sent'},
  'interests.noneReceived': {'hi': 'अभी तक कोई रुचि नहीं आई।', 'en': 'No interests received yet.'},
  'interests.noneSent':  {'hi': 'आपने अभी तक कोई रुचि नहीं भेजी।', 'en': 'You haven\'t sent any interests yet.'},
  'interests.pending':   {'hi': '⏳ प्रतीक्षित', 'en': '⏳ Pending'},
  'interests.accepted':  {'hi': '✓ स्वीकृत', 'en': '✓ Accepted'},
  'interests.rejected':  {'hi': 'अस्वीकृत', 'en': 'Rejected'},
  'interests.chat':      {'hi': 'बातचीत', 'en': 'Chat'},

  // ── Chats list ──
  'chats.title':         {'hi': 'बातचीत', 'en': 'Chats'},
  'chats.empty':         {'hi': 'अभी तक कोई मैच नहीं हुआ है। जब दोनों तरफ़ से रुचि स्वीकृत होगी, बातचीत यहाँ शुरू होगी।', 'en': 'No matches yet. Once interest is mutually accepted, chat starts here.'},
  'chats.startChat':     {'hi': 'बात शुरू करें!', 'en': 'Start chatting!'},

  // ── Chat screen ──
  'chat.online':         {'hi': 'ऑनलाइन', 'en': 'Online now'},
  'chat.creditsUsed':    {'hi': '%d क्रेडिट उपयोग · %d शेष', 'en': '%d credits used · %d remaining'},
  'chat.unlockNotice':   {'hi': 'इस बातचीत को खोलने में %d क्रेडिट लगेंगे', 'en': 'Opening this chat costs %d credits'},
  'chat.unlockCta':      {'hi': 'बातचीत खोलें (%d क्रेडिट)', 'en': 'Open chat (%d credits)'},
  'chat.insufficientCredits': {'hi': 'क्रेडिट कम हैं। वॉलेट से खरीदें।', 'en': 'Not enough credits. Top up your wallet.'},
  'chat.typeMessage':    {'hi': 'संदेश लिखें...', 'en': 'Type a message...'},
  'chat.startPrompt':    {'hi': 'बात शुरू करें! 👋', 'en': 'Start chatting! 👋'},
  'chat.sendPhoto':      {'hi': 'फ़ोटो भेजें', 'en': 'Send Photo'},

  // ── Wallet ──
  'wallet.title':          {'hi': 'वॉलेट', 'en': 'Wallet'},
  'wallet.available':      {'hi': 'उपलब्ध क्रेडिट', 'en': 'AVAILABLE CREDITS'},
  'wallet.remaining':      {'hi': '≈ %d चैट शेष', 'en': '≈ %d chat openings remaining'},
  'wallet.chatsOpened':    {'hi': 'खोली गई बातचीत', 'en': 'Chats opened'},
  'wallet.earned':         {'hi': 'रेफ़रल से कमाया', 'en': 'Earned (referral)'},
  'wallet.totalBought':    {'hi': 'कुल खरीदे', 'en': 'Total bought'},
  'wallet.buyCredits':     {'hi': 'क्रेडिट खरीदें · UPI / Razorpay', 'en': 'Buy credits · UPI / Razorpay'},
  'wallet.mostPopular':    {'hi': '★ सबसे लोकप्रिय', 'en': '★ Most popular'},
  'wallet.payVia':         {'hi': '%s का भुगतान करें (UPI / Razorpay) →', 'en': 'Pay %s via UPI / Razorpay →'},
  'wallet.referTitle':     {'hi': 'रेफ़र करें और मुफ़्त क्रेडिट पाएँ', 'en': 'Refer and earn free credits'},
  'wallet.referDesc':      {'hi': 'हर दोस्त के जुड़ने पर %d क्रेडिट', 'en': '%d credits per friend who joins'},
  'wallet.history':        {'hi': 'लेन-देन इतिहास', 'en': 'Transaction history'},
  'wallet.noHistory':      {'hi': 'अभी तक कोई लेन-देन नहीं।', 'en': 'No transactions yet.'},
  'wallet.txn.chatOpened': {'hi': 'बातचीत खोली गई', 'en': 'Chat opened'},
  'wallet.txn.referral':   {'hi': 'रेफ़रल से मिला', 'en': 'Referral earned'},
  'wallet.txn.purchase':   {'hi': 'पैक खरीदा गया', 'en': 'Pack purchased'},
  'wallet.txn.signupBonus':{'hi': 'स्वागत बोनस', 'en': 'Welcome bonus'},
  'wallet.txn.adReward':   {'hi': 'विज्ञापन देखा गया', 'en': 'Watched ad'},
  'wallet.paymentSuccess': {'hi': 'भुगतान सफल! क्रेडिट जुड़ गए।', 'en': 'Payment successful! Credits added.'},
  'wallet.paymentFailed':  {'hi': 'भुगतान असफल रहा।', 'en': 'Payment failed.'},
  'wallet.watchAd':        {'hi': 'विज्ञापन देखें और क्रेडिट कमाएँ', 'en': 'Watch an ad, earn credits'},
  'wallet.watchAdDesc':    {'hi': 'हर विज्ञापन पर %d क्रेडिट · आज %d/%d बचे', 'en': '%d credits per ad · %d/%d left today'},
  'wallet.watchAdCta':     {'hi': 'विज्ञापन देखें', 'en': 'Watch ad'},
  'wallet.adLoading':      {'hi': 'विज्ञापन लोड हो रहा है...', 'en': 'Loading ad...'},
  'wallet.adLimitReached': {'hi': 'आज की सीमा पूरी हो गई। कल फिर आएँ।', 'en': 'Daily limit reached. Come back tomorrow.'},
  'wallet.adFailed':       {'hi': 'विज्ञापन लोड नहीं हो पाया। दोबारा कोशिश करें।', 'en': 'Ad failed to load. Try again.'},
  'wallet.adRewardEarned': {'hi': '+%d क्रेडिट मिले!', 'en': '+%d credits earned!'},

  // ── Kundali ──
  'kundali.title':       {'hi': 'कुंडली मिलान', 'en': 'Kundali match'},
  'kundali.gunMilan':    {'hi': 'गुण मिलान', 'en': 'GUN MILAN'},
  'kundali.overall':     {'hi': 'कुल अनुकूलता', 'en': 'Overall compatibility'},
  'kundali.good':        {'hi': 'अच्छा मेल ✓', 'en': 'Good match ✓'},
  'kundali.average':     {'hi': 'सामान्य मेल', 'en': 'Average match'},
  'kundali.poor':        {'hi': 'कमज़ोर मेल', 'en': 'Weak match'},
  'kundali.outOf36':     {'hi': '%d में से 36 गुण मिले', 'en': '%d out of 36 gunas match'},
  'kundali.breakdown':   {'hi': 'कूट (गुण) विवरण', 'en': 'Koot (Guna) breakdown'},
  'kundali.koot':        {'hi': 'कूट', 'en': 'Koot'},
  'kundali.score':       {'hi': 'अंक', 'en': 'Score'},
  'kundali.max':         {'hi': 'अधिकतम', 'en': 'Max'},
  'kundali.disclaimerTitle': {'hi': '⚠ अस्वीकरण', 'en': '⚠ Disclaimer'},
  'kundali.disclaimer':  {'hi': 'कुंडली मिलान पारंपरिक वैदिक ज्योतिष पर आधारित केवल मार्गदर्शन है। अंतिम निर्णय में परिवार और योग्य पंडित की सलाह लें।', 'en': 'Kundali matching is based on traditional Vedic astrology for guidance only. Final decisions should involve family and a qualified pandit.'},
  'kundali.needDetails': {'hi': 'कुंडली मिलान के लिए दोनों प्रोफ़ाइल में राशि व नक्षत्र होना ज़रूरी है।', 'en': 'Both profiles need Rashi and Nakshatra filled in to run a kundali match.'},
  'kundali.manglik':     {'hi': 'मांगलिक', 'en': 'Manglik'},
  'kundali.yes':         {'hi': 'हाँ', 'en': 'Yes'},
  'kundali.no':          {'hi': 'नहीं', 'en': 'No'},

  // ── Profile ──
  'profile.completion':  {'hi': 'प्रोफ़ाइल पूर्णता', 'en': 'Profile completion'},
  'profile.completionHint': {'hi': 'बेहतर मिलान के लिए कुंडली विवरण जोड़ें', 'en': 'Add kundali details to improve matches'},
  'profile.aboutMe':     {'hi': 'मेरे बारे में', 'en': 'About me'},
  'profile.kundaliDetails': {'hi': 'कुंडली विवरण', 'en': 'Kundali details'},
  'profile.referFriend': {'hi': 'दोस्त को रेफ़र करें', 'en': 'Refer a friend'},
  'profile.referDesc':   {'hi': 'प्रति रेफ़रल %d क्रेडिट कमाएँ', 'en': 'Earn %d credits per referral'},
  'profile.verifyTitle': {'hi': 'सत्यापित हों', 'en': 'Get Verified'},
  'profile.verifyDesc':  {'hi': 'सत्यापित बैज से आपकी प्रोफ़ाइल पर ज़्यादा विश्वास मिलता है।', 'en': 'A verified badge builds more trust in your profile.'},
  'profile.verifyPending':  {'hi': 'सत्यापन प्रतीक्षित', 'en': 'Verification pending'},
  'profile.verifyRejected': {'hi': 'सत्यापन अस्वीकृत', 'en': 'Verification rejected'},
  'profile.verifyDone':     {'hi': 'प्रोफ़ाइल सत्यापित', 'en': 'Profile verified'},
  'profile.requestVerify':  {'hi': 'सत्यापन अनुरोध करें', 'en': 'Request verification'},
  'profile.notFound':    {'hi': 'प्रोफ़ाइल डेटा नहीं मिला।', 'en': 'Profile data not found.'},
};

extension StringsX on BuildContext {
  /// Whether the app-wide language toggle is currently set to Hindi.
  bool get isHindi => watch<LanguageController>().isHindi;

  /// t('home.suggested') → looked up in the language currently selected.
  /// Pass [args] to sprintf-style %s/%d placeholders in order.
  String t(String key, [List<Object>? args]) {
    final entry = _dict[key];
    var value = entry == null ? key : (isHindi ? entry['hi']! : entry['en']!);
    if (args != null) {
      for (final a in args) {
        value = value.replaceFirst(RegExp(r'%[ds]'), '$a');
      }
    }
    return value;
  }
}
