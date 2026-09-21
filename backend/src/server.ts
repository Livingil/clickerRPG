import { createApp } from "./app.js";
import { env } from "./config/env.js";
import { connectMongo } from "./db/mongoose.js";

await connectMongo();

const app = createApp();
app.listen(env.PORT, () => {
  console.log(`ClickerRPG backend listening on http://localhost:${env.PORT}`);
});
