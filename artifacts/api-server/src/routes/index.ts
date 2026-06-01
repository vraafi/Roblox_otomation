import { Router, type IRouter } from "express";
import healthRouter from "./health.js";
import agentRouter from "./agent/index.js";
import studioRouter from "./studio/index.js";

const router: IRouter = Router();

router.use(healthRouter);
router.use(agentRouter);
router.use(studioRouter);

export default router;
