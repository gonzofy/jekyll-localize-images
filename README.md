# Localize Images

This is a simple script that you run in a jekyll directory. It will download any and all images referenced in markdown files in the \_posts/ directory and save them in images/. It will then change the references in the markdown files in \_posts to be relative to the root (e.g. /images/foo.jpg).

The main purpose of this is for a blog that contain tons of references to your own images, such as personal travel blogs, so that you're not relying on your photo sharing site's willingness to serve the same file with the same URL forever. For example, Fotki would change the sharing URL without warning sometimes, which was very frustrating.
