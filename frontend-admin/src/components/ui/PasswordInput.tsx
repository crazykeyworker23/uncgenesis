import React, { forwardRef, useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';

type PasswordInputProps = Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'>;

/**
 * Campo de contraseña con interruptor para verla.
 *
 * Escribir una clave a ciegas es la causa mas comun de errores al iniciar
 * sesion o al asignarle credenciales a otra persona. El estado es local a cada
 * campo: revelar uno no revela los demas de la pantalla.
 *
 * Reenvia la referencia para poder usarse con `{...register('password')}`.
 */
export const PasswordInput = forwardRef<HTMLInputElement, PasswordInputProps>(
  ({ className = '', ...props }, ref) => {
    const [visible, setVisible] = useState(false);

    return (
      <div className="relative">
        <input
          ref={ref}
          type={visible ? 'text' : 'password'}
          // Espacio a la derecha para que el texto no quede bajo el icono.
          className={`${className} pr-11`}
          {...props}
        />
        <button
          type="button"
          onClick={() => setVisible((v) => !v)}
          disabled={props.disabled}
          title={visible ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          aria-label={visible ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-crema text-opacity-40 hover:text-opacity-80 transition-colors disabled:opacity-30"
        >
          {visible ? <EyeOff size={16} /> : <Eye size={16} />}
        </button>
      </div>
    );
  }
);

PasswordInput.displayName = 'PasswordInput';
