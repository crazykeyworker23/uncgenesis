import React from 'react';

interface LogoProps {
  className?: string;
  size?: number;
  variant?: 'gold' | 'white' | 'dark';
}

export const Logo: React.FC<LogoProps> = ({ 
  className = '', 
  size = 48, 
  variant: _variant = 'gold' 
}) => {
  return (
    <img
      src="/logo.png"
      alt="Génesis App Logo"
      width={size}
      height={size}
      style={{ width: size, height: size, objectFit: 'contain' }}
      className={`inline-block ${className}`}
    />
  );
};
