export interface ReportSummarySection {
  total: number;
  [key: string]: number;
}

export interface RequestMetrics {
  pending: number;
  in_progress: number;
  resolved: number;
  total: number;
}

export interface ReportSummary {
  cells: {
    total: number;
    active: number;
    inactive: number;
  };
  events: {
    total: number;
    registrations: number;
  };
  requests: {
    prayer: RequestMetrics;
    visitor: RequestMetrics;
  };
  users: {
    active: number;
    blocked: number;
    inactive: number;
    total: number;
  };
  notifications: {
    devices: number;
    sent: number;
  };
}
