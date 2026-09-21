import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import { HttpError } from "./errors.js";

export const errorMiddleware: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof ZodError) {
    res.status(400).json({ error: "Validation failed", details: error.flatten() });
    return;
  }
  if (error instanceof HttpError) {
    res.status(error.status).json({ error: error.message, details: error.details });
    return;
  }
  console.error(error);
  res.status(500).json({ error: "Internal server error" });
};
