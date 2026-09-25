import React from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import Hospitals from './pages/Hospitals';

function Home() {
  const navigate = useNavigate();
  return (
    <div className="max-w-4xl mx-auto text-center mt-10">
      <h2 className="text-3xl font-semibold mb-4">Find a Doctor & Book Appointments</h2>
      <p className="text-gray-600 mb-8">Discover nearby hospitals and specialists easily.</p>
      <button 
        onClick={() => navigate('/hospitals')}
        className="bg-blue-600 text-white px-6 py-2 rounded shadow hover:bg-blue-700"
      >
        Search Hospitals
      </button>
    </div>
  );
}

function App() {
  return (
    <Router>
      <div className="min-h-screen flex flex-col">
        <header className="bg-blue-600 text-white p-4 shadow-md flex justify-between items-center">
          <h1 className="text-xl font-bold cursor-pointer" onClick={() => window.location.href='/'}>HealthBook</h1>
        </header>
        <main className="flex-grow p-4">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/hospitals" element={<Hospitals />} />
            <Route path="*" element={<div className="text-center mt-10 text-red-500">404 - Not Found</div>} />
          </Routes>
        </main>
        <footer className="bg-gray-800 text-white p-4 text-center">
          <p>&copy; 2024 HealthBook Platform. All rights reserved.</p>
        </footer>
      </div>
    </Router>
  );
}

export default App;
