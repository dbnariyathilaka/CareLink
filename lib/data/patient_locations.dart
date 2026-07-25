// Saved patient care-address locations (stand-in for a backend "patients"
// table). Coordinates are real Sri Lankan locations so the directions
// screen can request an actual driving route between two real points.
class PatientLocation {
  final String address;
  final double lat;
  final double lng;

  const PatientLocation({required this.address, required this.lat, required this.lng});
}

const Map<String, PatientLocation> patientLocations = {
  'Nipuni Ariyathilaka': PatientLocation(
    address: '142 Galle Road, Colombo 03',
    lat: 6.9101,
    lng: 79.8478,
  ),
  'Kamal Perera': PatientLocation(
    address: '27 Havelock Road, Colombo 05',
    lat: 6.8845,
    lng: 79.8661,
  ),
  'Ishara Perera': PatientLocation(
    address: '58 Kandy Road, Kadawatha',
    lat: 7.0084,
    lng: 79.9515,
  ),
  'Ranjan Jayasuriya': PatientLocation(
    address: '9 Negombo Road, Wattala',
    lat: 6.9894,
    lng: 79.8912,
  ),
};

/// Fallback used when a patient has no saved location on file.
const PatientLocation defaultPatientLocation = PatientLocation(
  address: '142 Galle Road, Colombo 03',
  lat: 6.9101,
  lng: 79.8478,
);
