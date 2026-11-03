import React from 'react';
import ReactDOM from 'react-dom/client';
import { WebCompanionRouter } from './router';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <WebCompanionRouter />
  </React.StrictMode>
);
