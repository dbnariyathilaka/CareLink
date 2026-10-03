// Sri Lankan banks and branches for the caregiver payout-setup step.
//
// Bank codes are the real 4-digit SLIPS/LankaClear bank codes, cross-checked
// across 3 independent sources (Wikipedia's "Sri Lanka Interbank Payment
// System" article, thecodes.us, ceylonexchange.com.au) — all three agree
// with each other on every code below.
//
// Deliberately excluded from this list (not real personal-payout options):
// - Bank of China (Colombo Branch) — wholesale/corporate only, no verified
//   SLIPS code found in any source checked.
// - Deutsche Bank AG (Colombo Branch) — wholesale/corporate only, no
//   personal retail accounts.
// - Sri Lanka Savings Bank Ltd — currently operating out of National
//   Savings Bank premises pending a merger; no verified standalone code.
//
// Branch-level data is real but intentionally NOT a full national
// directory (the actual LankaClear directory has 1,300+ branches across
// all banks, too large to verify reliably by hand) — it only covers real,
// verified branches for the ~10 largest banks in the major cities this
// app already lists in sri_lankan_cities.dart. A bank with no entry in
// [SriLankanBank.branches] simply has no curated branch list yet; the
// onboarding screen falls back to a free-text branch field for those.
//
// Branch codes for Bank of Ceylon, People's Bank, Commercial Bank,
// Sampath Bank, Hatton National Bank, Seylan Bank, and NDB Bank were
// independently cross-verified against a second source (bankcodesfinder.com)
// in addition to thecodes.us. DFCC Bank, Nations Trust Bank, and Pan Asia
// Banking Corporation branch codes are single-sourced (thecodes.us only) —
// treat those as slightly lower confidence than the cross-verified ones.
//
// Bank of Ceylon is the one exception to "not a full directory" above — at
// the user's request, its branch list was substantially expanded using the
// Sri Lanka Department of Pensions' official branch-name circular (see that
// bank's own comment, inline below). `BankBranch.code` is nullable
// specifically to support this: a branch can be a real, confirmed BOC
// branch without yet having a verified SLIPS code attached. Never fill a
// null code with a guess — add a real, sourced one or leave it null.

class BankBranch {
  final String city;
  final String name;
  // 3-digit branch code — null means this branch's real existence and name
  // are confirmed (see each bank's own sourcing note), but no verified
  // branch code has been found for it yet. Never fabricated: a caregiver
  // picking one of these sees "code not yet verified" rather than a
  // plausible-looking but unconfirmed number.
  final String? code;

  const BankBranch({required this.city, required this.name, this.code});
}

class SriLankanBank {
  final String name;
  final String code; // 4-digit SLIPS bank code
  final List<BankBranch> branches;

  const SriLankanBank({required this.name, required this.code, this.branches = const []});
}

final List<SriLankanBank> sriLankanBanks = List<SriLankanBank>.unmodifiable(
  <SriLankanBank>[
    const SriLankanBank(name: 'Amãna Bank PLC', code: '7463'),
    const SriLankanBank(
      name: 'Bank of Ceylon',
      code: '7010',
      // BOC runs ~663 branches nationwide — a full directory with verified
      // codes isn't available from any single accessible source (BOC's own
      // branch locator at boc.lk/branches lists names/addresses only, no
      // codes, across 132 paginated results; third-party code aggregators
      // either lack full coverage or block automated access). The 13 marked
      // "— verified code" below are cross-checked the same way as the rest
      // of this file (see header comment). The remaining branches are real,
      // confirmed names — sourced from the Sri Lanka Department of
      // Pensions' official "Divisional Secretariats and Bank Branches"
      // circular (pensions.gov.lk, Bank-and-DS-Office-List-English.pdf,
      // LC_2023), which lists them as real BOC branches accepting
      // pensioners' life-certificate fingerprint confirmation — but that
      // document is a branch-name list for a DS/branch verification
      // programme, not a SLIPS branch-code directory, so it carries no
      // codes. Rather than invent one, those branches have `code: null` and
      // the picker UI shows "code not yet verified" for them.
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '001'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '004'),
        BankBranch(city: 'Colombo', name: 'Kollupitiya', code: '034'),
        BankBranch(city: 'Colombo', name: 'Bambalapitiya', code: '037'),
        BankBranch(city: 'Aluthgama', name: 'Aluthgama'),
        BankBranch(city: 'Ambalangoda', name: 'Ambalangoda'),
        BankBranch(city: 'Ampara', name: 'Ampara'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '022'),
        BankBranch(city: 'Avissawella', name: 'Avissawella'),
        BankBranch(city: 'Badulla', name: 'Badulla'),
        BankBranch(city: 'Balangoda', name: 'Balangoda'),
        BankBranch(city: 'Bandarawela', name: 'Bandarawela'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa Super Grade', code: '012'),
        BankBranch(city: 'Bibile', name: 'Bibile'),
        BankBranch(city: 'Colombo', name: 'Borella', code: '038'),
        BankBranch(city: 'Chilaw', name: 'Chilaw'),
        BankBranch(city: 'Dambulla', name: 'Dambulla'),
        BankBranch(city: 'Dehiattakandiya', name: 'Dehiattakandiya'),
        BankBranch(city: 'Digana', name: 'Digana'),
        BankBranch(city: 'Divulapitiya', name: 'Divulapitiya'),
        BankBranch(city: 'Embilipitiya', name: 'Embilipitiya'),
        BankBranch(city: 'Galagedara', name: 'Galagedara'),
        BankBranch(city: 'Galenbindunuwewa', name: 'Galenbindunuwewa'),
        BankBranch(city: 'Galgamuwa', name: 'Galgamuwa'),
        BankBranch(city: 'Galle', name: 'Galle Fort', code: '003'),
        BankBranch(city: 'Gampaha', name: 'Gampaha S/G', code: '045'),
        BankBranch(city: 'Gampola', name: 'Gampola'),
        BankBranch(city: 'Hambantota', name: 'Hambantota'),
        BankBranch(city: 'Hatton', name: 'Hatton'),
        BankBranch(city: 'Hikkaduwa', name: 'Hikkaduwa'),
        BankBranch(city: 'Hiripitiya', name: 'Hiripitiya'),
        BankBranch(city: 'Homagama', name: 'Homagama'),
        BankBranch(city: 'Horana', name: 'Horana'),
        BankBranch(city: 'Horowpathana', name: 'Horowpathana'),
        BankBranch(city: 'Ja-Ela', name: 'Ja-Ela'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '005'),
        BankBranch(city: 'Kadawata', name: 'Kadawata'),
        BankBranch(city: 'Kaduwela', name: 'Kaduwela'),
        BankBranch(city: 'Kalmunai', name: 'Kalmunai'),
        BankBranch(city: 'Kalutara', name: 'Kalutara'),
        BankBranch(city: 'Kamburupitiya', name: 'Kamburupitiya'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '002'),
        BankBranch(city: 'Katugastota', name: 'Katugastota'),
        BankBranch(city: 'Kegalle', name: 'Kegalle'),
        BankBranch(city: 'Kekirawa', name: 'Kekirawa'),
        BankBranch(city: 'Kilinochchi', name: 'Kilinochchi'),
        BankBranch(city: 'Kiribathgoda', name: 'Kiribathgoda'),
        BankBranch(city: 'Kirindiwela', name: 'Kirindiwela'),
        BankBranch(city: 'Kuliyapitiya', name: 'Kuliyapitiya'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '009'),
        BankBranch(city: 'Mahiyangana', name: 'Mahiyangana'),
        BankBranch(city: 'Maho', name: 'Maho'),
        BankBranch(city: 'Malabe', name: 'Malabe'),
        BankBranch(city: 'Mannar', name: 'Mannar'),
        BankBranch(city: 'Matale', name: 'Matale'),
        BankBranch(city: 'Matara', name: 'Matara', code: '024'),
        BankBranch(city: 'Matugama', name: 'Matugama'),
        BankBranch(city: 'Mawanella', name: 'Mawanella'),
        BankBranch(city: 'Medawachchiya', name: 'Medawachchiya'),
        BankBranch(city: 'Melsiripura', name: 'Melsiripura'),
        BankBranch(city: 'Mihintale', name: 'Mihintale'),
        BankBranch(city: 'Minuwangoda', name: 'Minuwangoda'),
        BankBranch(city: 'Mirigama', name: 'Mirigama'),
        BankBranch(city: 'Moneragala', name: 'Moneragala'),
        BankBranch(city: 'Moratuwa', name: 'Moratuwa'),
        BankBranch(city: 'Mullativu', name: 'Mullativu'),
        BankBranch(city: 'Nawalapitiya', name: 'Nawalapitiya'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '018'),
        BankBranch(city: 'Nikaweratiya', name: 'Nikaweratiya'),
        BankBranch(city: 'Nittambuwa', name: 'Nittambuwa'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '049'),
        BankBranch(city: 'Nuwara Eliya', name: 'Nuwara Eliya'),
        BankBranch(city: 'Padukka', name: 'Padukka'),
        BankBranch(city: 'Panadura', name: 'Panadura'),
        BankBranch(city: 'Piliyandala', name: 'Piliyandala'),
        BankBranch(city: 'Polgahawela', name: 'Polgahawela'),
        BankBranch(city: 'Polonnaruwa', name: 'Polonnaruwa'),
        BankBranch(city: 'Puttalam', name: 'Puttalam'),
        BankBranch(city: 'Rambukkana', name: 'Rambukkana'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '031'),
        BankBranch(city: 'Rikillagaskada', name: 'Rikillagaskada'),
        BankBranch(city: 'Siyambalanduwa', name: 'Siyambalanduwa'),
        BankBranch(city: 'Talatuoya', name: 'Talatuoya'),
        BankBranch(city: 'Tangalle', name: 'Tangalle'),
        BankBranch(city: 'Colombo', name: 'Taprobane'),
        BankBranch(city: 'Thambuttegama', name: 'Thambuttegama'),
        BankBranch(city: 'Trincomalee', name: 'Trincomalee', code: '006'),
        BankBranch(city: 'Vavuniya', name: 'Vavuniya'),
        BankBranch(city: 'Walasmulla', name: 'Walasmulla'),
        BankBranch(city: 'Wariyapola', name: 'Wariyapola'),
        BankBranch(city: 'Weligama', name: 'Weligama'),
        BankBranch(city: 'Colombo', name: 'Wellawatta'),
        BankBranch(city: 'Wennappuwa', name: 'Wennappuwa'),
        BankBranch(city: 'Yakkalamulla', name: 'Yakkalamulla'),
      ],
    ),
    const SriLankanBank(name: 'Cargills Bank PLC', code: '7481'),
    const SriLankanBank(name: 'Citibank, N.A.', code: '7047'),
    const SriLankanBank(
      name: 'Commercial Bank of Ceylon PLC',
      code: '7056',
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '002'),
        BankBranch(city: 'Colombo', name: 'Colombo 7', code: '050'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '013'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '004'),
        BankBranch(city: 'Galle', name: 'Galle Fort', code: '005'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '006'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '016'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '044'),
        BankBranch(city: 'Matara', name: 'Matara', code: '222'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '053'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '049'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '105'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '020'),
      ],
    ),
    const SriLankanBank(
      name: 'DFCC Bank PLC',
      code: '7454',
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '007'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '046'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '018'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '006'),
        BankBranch(city: 'Galle', name: 'Galle', code: '035'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '042'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '005'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '010'),
        BankBranch(city: 'Matara', name: 'Matara', code: '004'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '009'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '008'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '040'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '002'),
      ],
    ),
    const SriLankanBank(name: 'Habib Bank Limited', code: '7074'),
    const SriLankanBank(
      name: 'Hatton National Bank PLC',
      code: '7083',
      branches: [
        BankBranch(city: 'Colombo', name: 'Aluthkade', code: '001'),
        BankBranch(city: 'Colombo', name: 'City Office', code: '002'),
        BankBranch(city: 'Colombo', name: 'Head Office', code: '003'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '024'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '018'),
        BankBranch(city: 'Galle', name: 'Galle', code: '013'),
        BankBranch(city: 'Jaffna', name: 'Jaffna Metro', code: '016'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '019'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '010'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '030'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '057'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '027'),
      ],
    ),
    const SriLankanBank(name: 'HDFC Bank of Sri Lanka', code: '7737'),
    const SriLankanBank(
      name: 'HSBC (The Hongkong & Shanghai Banking Corp. Ltd)',
      code: '7092',
    ),
    const SriLankanBank(name: 'Indian Bank', code: '7108'),
    const SriLankanBank(name: 'Indian Overseas Bank', code: '7117'),
    const SriLankanBank(name: 'MCB Bank Limited', code: '7269'),
    const SriLankanBank(
      name: 'National Development Bank PLC (NDB)',
      code: '7214',
      branches: [
        BankBranch(city: 'Colombo', name: 'Pettah', code: '043'),
        BankBranch(city: 'Colombo', name: 'Kollupitiya', code: '014'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '009'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '002'),
        BankBranch(city: 'Galle', name: 'Galle', code: '021'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '037'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '007'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '029'),
        BankBranch(city: 'Matara', name: 'Matara', code: '006'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '019'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '013'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '039'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '004'),
      ],
    ),
    const SriLankanBank(name: 'National Savings Bank', code: '7719'),
    const SriLankanBank(
      name: 'Nations Trust Bank PLC',
      code: '7162',
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '001'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '008'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '007'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '004'),
        BankBranch(city: 'Galle', name: 'Galle', code: '029'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '035'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '012'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '018'),
        BankBranch(city: 'Matara', name: 'Matara', code: '028'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '039'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '041'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '034'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda Mini', code: '053'),
      ],
    ),
    const SriLankanBank(
      name: 'Pan Asia Banking Corporation PLC',
      code: '7311',
      branches: [
        BankBranch(city: 'Colombo', name: 'Metro', code: '001'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '004'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '010'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '005'),
        BankBranch(city: 'Galle', name: 'Galle', code: '025'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '037'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '012'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '011'),
        BankBranch(city: 'Matara', name: 'Matara', code: '013'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '032'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '007'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '040'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '008'),
      ],
    ),
    const SriLankanBank(
      name: "People's Bank",
      code: '7135',
      branches: [
        BankBranch(city: 'Colombo', name: 'Duke Street', code: '001'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '034'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '003'),
        BankBranch(city: 'Galle', name: 'Galle Fort', code: '013'),
        BankBranch(city: 'Jaffna', name: 'Jaffna Main Street', code: '104'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '012'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '026'),
        BankBranch(city: 'Matara', name: 'Matara Uyanwatte', code: '032'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '008'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '088'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '075'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '174'),
      ],
    ),
    const SriLankanBank(name: 'Pradeshiya Sanwardhana Bank', code: '7755'),
    const SriLankanBank(name: 'Public Bank Berhad', code: '7296'),
    const SriLankanBank(
      name: 'Sampath Bank PLC',
      code: '7278',
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '001'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '002'),
        BankBranch(city: 'Colombo', name: 'Fort', code: '012'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '024'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '007'),
        BankBranch(city: 'Galle', name: 'Galle Super', code: '035'),
        BankBranch(city: 'Galle', name: 'Galle Bazaar', code: '159'),
        BankBranch(city: 'Jaffna', name: 'Sampath Jaffna', code: '120'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '006'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '016'),
        BankBranch(city: 'Matara', name: 'Matara', code: '010'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura Super', code: '021'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '033'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '139'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '003'),
      ],
    ),
    const SriLankanBank(name: 'Sanasa Development Bank PLC', code: '7728'),
    const SriLankanBank(
      name: 'Seylan Bank PLC',
      code: '7287',
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '001'),
        BankBranch(city: 'Colombo', name: 'Colombo Fort', code: '030'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '013'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '017'),
        BankBranch(city: 'Galle', name: 'Galle', code: '016'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '085'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '018'),
        BankBranch(city: 'Gampaha', name: 'Gampaha', code: '011'),
        BankBranch(city: 'Matara', name: 'Matara', code: '002'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '021'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '007'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '073'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '012'),
      ],
    ),
    const SriLankanBank(name: 'Standard Chartered Bank', code: '7038'),
    const SriLankanBank(name: 'State Bank of India', code: '7144'),
    const SriLankanBank(name: 'State Mortgage & Investment Bank', code: '7764'),
    const SriLankanBank(name: 'Union Bank of Colombo PLC', code: '7302'),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
);
