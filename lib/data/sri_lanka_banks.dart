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

class BankBranch {
  final String city;
  final String name;
  final String code; // 3-digit branch code

  const BankBranch({required this.city, required this.name, required this.code});
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
      branches: [
        BankBranch(city: 'Colombo', name: 'City Office', code: '001'),
        BankBranch(city: 'Colombo', name: 'Pettah', code: '004'),
        BankBranch(city: 'Colombo', name: 'Kollupitiya', code: '034'),
        BankBranch(city: 'Colombo', name: 'Bambalapitiya', code: '037'),
        BankBranch(city: 'Colombo', name: 'Borella S/G', code: '038'),
        BankBranch(city: 'Negombo', name: 'Negombo', code: '018'),
        BankBranch(city: 'Kandy', name: 'Kandy', code: '002'),
        BankBranch(city: 'Galle', name: 'Galle Fort', code: '003'),
        BankBranch(city: 'Jaffna', name: 'Jaffna', code: '005'),
        BankBranch(city: 'Kurunegala', name: 'Kurunegala', code: '009'),
        BankBranch(city: 'Gampaha', name: 'Gampaha S/G', code: '045'),
        BankBranch(city: 'Matara', name: 'Matara', code: '024'),
        BankBranch(city: 'Anuradhapura', name: 'Anuradhapura', code: '022'),
        BankBranch(city: 'Ratnapura', name: 'Ratnapura', code: '031'),
        BankBranch(city: 'Batticaloa', name: 'Batticaloa', code: '012'),
        BankBranch(city: 'Nugegoda', name: 'Nugegoda', code: '049'),
        BankBranch(city: 'Trincomalee', name: 'Trincomalee', code: '006'),
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
