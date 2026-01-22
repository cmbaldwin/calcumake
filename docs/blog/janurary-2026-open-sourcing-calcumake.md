# Open Sourcing CalcuMake: Run Your Own Pricing Calculator for $6/Month

**Author:** CalcuMake Team
**Published:** January 22, 2026
**Featured:** Yes

---

## Excerpt

We have open sourced CalcuMake! For the price of a cheap VPS ($6/month), you can run this powerful 3D print pricing tool on your own server. Plus, with a little know-how, you can host other projects on the same server too.

---

We are thrilled to announce that **CalcuMake is now open source**!

We believe that powerful tools should be accessible to everyone. While there are other 3D print pricing calculators out there with base plans starting around $6 USD per month, we wanted to offer you something even better: **freedom and ownership**.

## Easy Setup with AI

**Never set up a server before? No problem.**

It is **especially easy** now to get started. You don't need to be a Linux expert. You can work with an AI assistant (like ChatGPT, Claude, or Gemini) to guide you through setting up your server step-by-step. You could probably get this entirely set up in a few hours, likely even using **free-tier credits**!

## Why Open Source?

For about the same price as a competitor's monthly subscription (~$6 USD), you can rent your own Virtual Private Server (VPS) and run CalcuMake yourself. But here's the kicker: **you're not limited to just one app.**

When you run your own server, you have the freedom to host:
- CalcuMake for your 3D printing business
- Your own personal website or portfolio
- Home automation tools
- Other open-source software

All on the same $6 box! It's an incredible value proposition for anyone willing to invest a little bit of time.

## Setting It Up: Easier Than You Think

The hardest part of this journey is simply setting up the server itself. We personally use and recommend **Hetzner** for their reliable and affordable VPS offerings, but any provider (DigitalOcean, Linode, AWS Lightsail) will work just fine.

Once you have your server, deploying CalcuMake is straightforward. We've designed the application to be as friendly as possible for self-hosters.

### Pro Tip: Dummy Secrets

One of the biggest hurdles in setting up complex web applications is often dealing with third-party integrations like payment gateways.

**Here's the secret:** Since you are likely using this for yourself or your internal team and don't need to charge users, you can simply **fill in dummy/fake passwords** for integrations like Stripe!

The app is built to be resilient. You can populate the required environment variables with placeholder text, and utilize the core features of the calculator—creating materials, managing printers, and generating quotes—without ever needing a real merchant account. Use the app "as is" and start pricing your prints immediately.

## The Technical Stuff: Secrets & Registries

"But what about all those passwords and keys?" you might ask. Great question.

### Handling Secrets Safely

Modern web applications use "secrets" (API keys, database passwords, tokens) to talk to other services securely. In CalcuMake, these lived in a `.env` file (or encrypted credentials).

When you self-host, you'll need to generate these secrets. We strongly recommend using a **Password Manager** like **1Password**, **Bitwarden** (which is free for individuals!), or **KeePassXC**. These tools identify you're serious about security and can generate long, random, secure strings for things like your `RAILS_MASTER_KEY` or database passwords.

### Container Registries: AWS ECR vs. Local

To run CalcuMake, the code is packaged into a "Docker Image." Usually, these images are stored in a cloud service called a **Container Registry**.

We use **AWS ECR (Elastic Container Registry)**. It's robust and secure, but it's a paid service.

**Great News for You:** You don't need to pay for ECR! The deployment tool we use, **Kamal**, now supports a **Local Container Registry**. This means your generic $6 VPS can hold the images itself, completely freely. No AWS account required.

## Peek into the Future: What's Already Built?

We aren't just stoping at open sourcing the current version. We have some exciting features that are **already coded** and sitting in our pipeline, just waiting to be tested, merged, and deployed:

1.  **AI Conversation Integration:** We've built an integration with **OpenRouter** to bring AI-powered assistance directly into CalcuMake.
2.  **3MF/STL Import Tool:** A new tool to directly import 3D model files (3MF and STL) for even faster and more accurate pricing.

These features are right around the corner. If you're a developer and want to see them go live faster, check out the pull requests and help us test them!

## A Bit of Philosophy

I currently think that software is heading in the direction of disposability. It will be **SO** easy to do this on your own, people will be doing it.

It used to be that updates were slow, almost treated like hardware. I think now, as more people run their own apps with their own stack, apps will be more like animals. They'll share DNA, but instead of one app having many users, there will be many apps with single users. Those apps will adapt to the niche of **you**—meaning app code will be more like a species, and your deployment will be like an individual animal in that species.

This will allow software to evolve more quickly, especially if it's open for AIs to play with. AIs themselves, I think, will move in this direction as well—they already have.

## Join the Community

By open sourcing CalcuMake, we're inviting you to not just use the tool, but to own it. Check out the repository, fork the code, and maybe even contribute back if you add a cool new feature.

Happy Printing (and Hosting)!

---

## SEO Metadata

**Meta Description:** CalcuMake is now open source! Learn how to self-host your own 3D print pricing calculator for just $6/month using a VPS like Hetzner. Run multiple apps and use dummy secrets for easy setup.

**Meta Keywords:** open source 3d print calculator, self-hosted pricing tool, calcumake open source, hetzner vps hosting, run your own server, free 3d print calculator, rails open source
