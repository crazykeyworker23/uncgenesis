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
import { MyCell } from '../pages/MyCell';

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
      {/* Cada sección declara su permiso: escribir la URL a mano tampoco da
          acceso a lo que el rol no puede gestionar. */}
      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />

          {/* Gestión de célula: líder, coordinador y pastorado */}
          <Route element={<ProtectedRoute requiresCellScope />}>
            <Route path="/mi-celula" element={<MyCell />} />
          </Route>

          {/* Publications Routes */}
          <Route element={<ProtectedRoute permission="PUBLICATIONS_VIEW" />}>
            <Route path="/publicaciones" element={<PublicationList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT']} />}>
            <Route path="/publicaciones/nueva" element={<PublicationForm />} />
            <Route path="/publicaciones/:id/editar" element={<PublicationForm />} />
          </Route>

          {/* Services Routes */}
          <Route element={<ProtectedRoute permission="SERVICES_VIEW" />}>
            <Route path="/servicios" element={<ServiceList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['SERVICES_CREATE', 'SERVICES_EDIT']} />}>
            <Route path="/servicios/nuevo" element={<ServiceForm />} />
            <Route path="/servicios/:id/editar" element={<ServiceForm />} />
          </Route>

          {/* Devotionals Routes */}
          <Route element={<ProtectedRoute permission="DEVOTIONALS_VIEW" />}>
            <Route path="/devocionales" element={<DevotionalList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['DEVOTIONALS_CREATE', 'DEVOTIONALS_EDIT']} />}>
            <Route path="/devocionales/nuevo" element={<DevotionalForm />} />
            <Route path="/devocionales/:id/editar" element={<DevotionalForm />} />
          </Route>

          {/* Events Routes */}
          <Route element={<ProtectedRoute permission="EVENTS_VIEW" />}>
            <Route path="/eventos" element={<EventList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['EVENTS_CREATE', 'EVENTS_EDIT']} />}>
            <Route path="/eventos/nuevo" element={<EventForm />} />
            <Route path="/eventos/:id/editar" element={<EventForm />} />
          </Route>

          {/* Cells Routes */}
          <Route element={<ProtectedRoute permission="CELLS_VIEW" />}>
            <Route path="/celulas" element={<CellList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['CELLS_CREATE', 'CELLS_EDIT']} />}>
            <Route path="/celulas/nueva" element={<CellForm />} />
            <Route path="/celulas/:id/editar" element={<CellForm />} />
          </Route>

          {/* Notifications Routes */}
          <Route element={<ProtectedRoute permission="NOTIFICATIONS_VIEW" />}>
            <Route path="/notificaciones" element={<NotificationList />} />
          </Route>
          <Route element={<ProtectedRoute permission={['NOTIFICATIONS_CREATE', 'NOTIFICATIONS_SEND']} />}>
            <Route path="/notificaciones/nueva" element={<NotificationForm />} />
          </Route>

          {/* Requests Routes */}
          <Route element={<ProtectedRoute permission="REQUESTS_VIEW" />}>
            <Route path="/solicitudes" element={<Navigate to="/solicitudes/oraciones" replace />} />
            <Route path="/solicitudes/oraciones" element={<PrayerRequestList />} />
            <Route path="/solicitudes/visitas" element={<VisitorRequestList />} />
          </Route>

          {/* Users Routes */}
          <Route element={<ProtectedRoute permission="USERS_VIEW" />}>
            <Route path="/usuarios" element={<UserList />} />
          </Route>
          <Route element={<ProtectedRoute permission="USERS_EDIT" />}>
            <Route path="/usuarios/nuevo" element={<UserForm />} />
            <Route path="/usuarios/:id/editar" element={<UserForm />} />
          </Route>

          {/* Roles Routes */}
          <Route element={<ProtectedRoute permission="ROLES_VIEW" />}>
            <Route path="/roles" element={<RoleList />} />
          </Route>
          <Route element={<ProtectedRoute permission="MEDIA_VIEW" />}>
            <Route path="/multimedia" element={<MultimediaList />} />
          </Route>
          <Route element={<ProtectedRoute permission="REPORTS_VIEW" />}>
            <Route path="/reportes" element={<ReportList />} />
          </Route>
          <Route element={<ProtectedRoute permission="SETTINGS_VIEW" />}>
            <Route path="/configuracion" element={<Configuracion />} />
          </Route>
        </Route>
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
