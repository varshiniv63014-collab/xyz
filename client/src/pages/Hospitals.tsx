import React, { useEffect, useState } from 'react';

export default function Hospitals() {
  const [hospitals, setHospitals] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // We will fetch from our Express backend API
    fetch('/api/hospitals')
      .then(res => res.json())
      .then(data => {
        setHospitals(data.hospitals || []);
        setLoading(false);
      })
      .catch(err => {
        console.error("Error fetching hospitals:", err);
        setLoading(false);
      });
  }, []);

  return (
    <div className="max-w-6xl mx-auto mt-8">
      <h2 className="text-3xl font-semibold mb-6">Nearby Hospitals</h2>
      
      {loading ? (
        <p className="text-gray-500">Loading hospitals...</p>
      ) : hospitals.length === 0 ? (
        <p className="text-gray-500">No hospitals found in the database yet.</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {hospitals.map((hospital: any) => (
            <div key={hospital.id} className="bg-white p-6 rounded shadow border">
              <h3 className="text-xl font-bold mb-2">{hospital.name}</h3>
              <p className="text-gray-600 mb-2">{hospital.address}, {hospital.city}</p>
              <div className="mt-4 flex gap-2">
                {hospital.emergency_available && (
                  <span className="bg-red-100 text-red-700 text-xs px-2 py-1 rounded">Emergency</span>
                )}
                <span className="bg-blue-100 text-blue-700 text-xs px-2 py-1 rounded">{hospital.hospital_type}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
