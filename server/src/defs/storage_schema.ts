import type { BucketDef } from "../__generated__/server-types";

/**
 * Storage buckets for the pizzaria app.
 */

export const sounds: BucketDef<"sounds"> = {
  bucket_name: "sounds",
  description: "Notification sounds"
};
