import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';
import { AdminLayout } from '../layouts/AdminLayout';
import { Login } from '../pages/Login';
import { Dashboard } from '../pages/Dashboard';
import { PublicationList } from '../pages/PublicationList';
import { PublicationForm } from '../pages/PublicationForm';
import { ServiceList } from '../pages/ServiceList';
import { ServiceForm } from '../pages/ServiceForm';
import { DevotionalList } from '../pages/DevotionalList';
import { DevotionalForm } from '../pages/DevotionalForm';
import { EventList } from '../pages/EventList';
import { EventForm } from '../pages/EventForm';
import { CellList } from '../pages/CellList';
import { CellForm } from '../pages/CellForm';

import { PrayerRequestList } from '../pages/PrayerRequestList';
import { VisitorRequestList } from '../pages/VisitorRequestList';
import { NotificationList } from '../pages/NotificationList';
import { NotificationForm } from '../pages/NotificationForm';
import { UserList } from '../pages/UserList';
import { UserForm } from '../pages/UserForm';
import { RoleList } from '../pages/RoleList';
import { MultimediaList } from '../pages/MultimediaList';
import { ReportList } from '../pages/ReportList';
import { Configuracion } from '../pages/Configuracion';


export default function AppRouter() {
  return (
    <Routes>
      {/* Public Route */}
      <Route path="/login" element={<Login />} />
      
      {/* Protected Routes */}
      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />
          
          {/* Publications Routes */}
          <Route path="/publicaciones" element={<PublicationList />} />
          <Route path="/publicaciones/nueva" element={<PublicationForm />} />
          <Route path="/publicaciones/:id/editar" element={<PublicationForm />} />
          
          {/* Services Routes */}
          <Route path="/servicios" element={<ServiceList />} />
          <Route path="/servicios/nuevo" element={<ServiceForm />} />
          <Route path="/servicios/:id/editar" element={<ServiceForm />} />
          
          {/* Devotionals Routes */}
          <Route path="/devocionales" element={<DevotionalList />} />
          <Route path="/devocionales/nuevo" element={<DevotionalForm />} />
          <Route path="/devocionales/:id/editar" element={<DevotionalForm />} />
          
          {/* Events Routes */}
          <Route path="/eventos" element={<EventList />} />
          <Route path="/eventos/nuevo" element={<EventForm />} />
          <Route path="/eventos/:id/editar" element={<EventForm />} />
          {/* Cells Routes */}
          <Route path="/celulas" element={<CellList />} />
          <Route path="/celulas/nueva" element={<CellForm />} />
          <Route path="/celulas/:id/editar" element={<CellForm />} />
          {/* Notifications Routes */}
          <Route path="/notificaciones" element={<NotificationList />} />
          <Route path="/notificaciones/nueva" element={<NotificationForm />} />
          {/* Requests Routes */}
          <Route path="/solicitudes" element={<Navigate to="/solicitudes/oraciones" replace />} />
          <Route path="/solicitudes/oraciones" element={<PrayerRequestList />} />
          <Route path="/solicitudes/visitas" element={<VisitorRequestList />} />

          {/* Users Routes */}
          <Route path="/usuarios" element={<UserList />} />
          <Route path="/usuarios/nuevo" element={<UserForm />} />
          <Route path="/usuarios/:id/editar" element={<UserForm />} />
          
          {/* Roles Routes */}
          <Route path="/roles" element={<RoleList />} />
          <Route path="/multimedia" element={<MultimediaList />} />
          <Route path="/reportes" element={<ReportList />} />
          <Route path="/configuracion" element={<Configuracion />} />
        </Route>
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
