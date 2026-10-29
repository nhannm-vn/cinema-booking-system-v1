// Ambient type declarations for Deno runtime and JSR modules in Supabase Edge Functions.

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
  }
  export const env: Env;

  export interface ServeOptions {
    port?: number;
    hostname?: string;
    signal?: AbortSignal;
    onError?: (error: unknown) => Response | Promise<Response>;
    onListen?: (params: { port: number; hostname: string }) => void;
  }

  export function serve(
    handler: (req: Request) => Promise<Response> | Response,
    options?: ServeOptions
  ): void;
  export function serve(
    options: ServeOptions,
    handler: (req: Request) => Promise<Response> | Response
  ): void;
}

declare module "jsr:@supabase/supabase-js@2" {
  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any
  ): any;
}
