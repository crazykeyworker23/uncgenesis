import React, { useState } from 'react';
import { Link, useLocation, Outlet } from 'react-router-dom';
import { 
  LayoutDashboard, 
  BookOpen, 
  Calendar, 
  Users, 
  Bell, 
  MessageSquare, 
  UserSquare2, 
  ShieldCheck, 
  Image as ImageIcon, 
  BarChart3, 
  Settings,
  LogOut,
  Menu,
  X,
  Search,
  ChevronDown
} from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { Logo } from '../components/ui/Logo';

export const AdminLayout: React.FC = () => {
  const location = useLocation();
  const { user, logout } = useAuthStore();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);

  const menuItems = [
    { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
    { name: 'Publicaciones', path: '/publicaciones', icon: BookOpen },
    { name: 'Servicios', path: '/servicios', icon: MessageSquare },
    { name: 'Devocionales', path: '/devocionales', icon: BookOpen },
    { name: 'Células', path: '/celulas', icon: Users },
    { name: 'Eventos', path: '/eventos', icon: Calendar },
    { name: 'Notificaciones', path: '/notificaciones', icon: Bell },
    { name: 'Solicitudes', path: '/solicitudes', icon: MessageSquare },
    { name: 'Usuarios', path: '/usuarios', icon: UserSquare2 },
    { name: 'Roles y Permisos', path: '/roles', icon: ShieldCheck },
    { name: 'Biblioteca', path: '/multimedia', icon: ImageIcon },
    { name: 'Reportes', path: '/reportes', icon: BarChart3 },
    { name: 'Configuración', path: '/configuracion', icon: Settings },
  ];

  return (
    <div className="flex h-screen overflow-hidden bg-deep-teal text-crema">
      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black bg-opacity-50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar Component */}
      <aside 
        className={`fixed inset-y-0 left-0 z-50 flex flex-col w-64 bg-dark-teal border-r border-white border-opacity-5 transition-transform duration-300 transform lg:static lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Sidebar Header */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-white border-opacity-5 bg-deep-teal">
          <Link to="/" className="flex items-center gap-3" onClick={() => setSidebarOpen(false)}>
            <Logo size={36} variant="gold" />
            <div className="flex flex-col">
              <span className="font-extrabold text-lg leading-none tracking-wider text-dorado">GÉNESIS</span>
              <span className="text-xs text-crema text-opacity-60 leading-none mt-1">Panel Administrativo</span>
            </div>
          </Link>
          <button className="lg:hidden" onClick={() => setSidebarOpen(false)}>
            <X size={20} />
          </button>
        </div>

        {/* Sidebar Navigation */}
        <nav className="flex-1 px-4 py-6 overflow-y-auto space-y-1">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname.startsWith(item.path);
            return (
              <Link
                key={item.name}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${
                  isActive 
                    ? 'bg-dorado bg-opacity-10 text-dorado border-l-4 border-dorado pl-3' 
                    : 'text-crema text-opacity-70 hover:bg-white hover:bg-opacity-5 hover:text-crema'
                }`}
              >
                <Icon size={18} className={isActive ? 'text-dorado' : 'text-crema text-opacity-50'} />
                {item.name}
              </Link>
            );
          })}
        </nav>

        {/* Sidebar Footer */}
        <div className="p-4 border-t border-white border-opacity-5 bg-dark-green bg-opacity-30">
          <button 
            onClick={logout}
            className="flex items-center justify-center gap-2 w-full px-4 py-3 bg-error-red bg-opacity-10 text-error-red hover:bg-error-red hover:bg-opacity-20 font-semibold rounded-xl text-sm transition-all duration-200"
          >
            <LogOut size={16} />
            Cerrar Sesión
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Topbar */}
        <header className="flex items-center justify-between px-6 py-4 border-b border-white border-opacity-5 bg-dark-teal bg-opacity-30 backdrop-blur-md">
          {/* Menu Button for mobile */}
          <button 
            className="lg:hidden text-crema focus:outline-none"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu size={24} />
          </button>

          {/* Search input */}
          <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-deep-teal bg-opacity-40 border border-white border-opacity-10 rounded-xl w-72">
            <Search size={16} className="text-crema text-opacity-40" />
            <input 
              type="text" 
              placeholder="Buscar contenido, usuarios..." 
              className="bg-transparent border-none text-xs text-crema placeholder-crema placeholder-opacity-40 focus:outline-none w-full"
            />
          </div>

          {/* Right Header items */}
          <div className="flex items-center gap-4 ml-auto">
            {/* Notifications Bell */}
            <button className="relative p-2 rounded-xl hover:bg-white hover:bg-opacity-5 transition-colors">
              <Bell size={18} className="text-crema text-opacity-70" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-dorado rounded-full glowing-gold" />
            </button>

            {/* Profile Dropdown */}
            <div className="relative">
              <button 
                onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
                className="flex items-center gap-2 p-1 px-2 rounded-xl hover:bg-white hover:bg-opacity-5 transition-all focus:outline-none"
              >
                <div className="w-8 h-8 rounded-lg bg-dorado bg-opacity-20 flex items-center justify-center font-bold text-dorado border border-dorado border-opacity-30 overflow-hidden">
                  {user?.avatar ? (
                    <img src={user.avatar} alt="Avatar" className="w-full h-full object-cover" />
                  ) : (
                    user?.first_name?.charAt(0) || 'A'
                  )}
                </div>
                <div className="hidden sm:flex flex-col text-left">
                  <span className="text-xs font-semibold leading-none">{user?.full_name}</span>
                  <span className="text-[10px] text-crema text-opacity-50 leading-none mt-1">Administrador</span>
                </div>
                <ChevronDown size={14} className="text-crema text-opacity-50" />
              </button>

              {profileDropdownOpen && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setProfileDropdownOpen(false)} />
                  <div className="absolute right-0 mt-2 w-48 z-20 glass-panel border border-white border-opacity-10 shadow-lg p-1 bg-dark-teal bg-opacity-95">
                    <Link 
                      to="/configuracion" 
                      onClick={() => setProfileDropdownOpen(false)}
                      className="flex items-center gap-2 px-4 py-2 text-xs rounded-xl hover:bg-white hover:bg-opacity-5"
                    >
                      <Settings size={14} />
                      Mi Perfil
                    </Link>
                    <button 
                      onClick={() => {
                        setProfileDropdownOpen(false);
                        logout();
                      }}
                      className="flex items-center gap-2 w-full text-left px-4 py-2 text-xs text-error-red rounded-xl hover:bg-error-red hover:bg-opacity-10"
                    >
                      <LogOut size={14} />
                      Cerrar Sesión
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </header>

        {/* Dynamic Route Content */}
        <main className="flex-1 overflow-y-auto bg-deep-teal p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
