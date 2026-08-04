import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.bytedeco.javacv.Frame;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;

public class TestThumb {
    public static void main(String[] args) throws Exception {
        File video = new File(args[0]);
        System.out.println("Vidéo: " + video.getAbsolutePath());

        try (FFmpegFrameGrabber grabber = new FFmpegFrameGrabber(video)) {
            grabber.start();
            System.out.println("Longueur (frames): " + grabber.getLengthInVideoFrames());
            System.out.println("Durée (µs): " + grabber.getLengthInTime());
            System.out.println("FPS: " + grabber.getFrameRate());
            System.out.println("Format: " + grabber.getPixelFormat());

            // Test à 10% des frames
            int nbFrames = grabber.getLengthInVideoFrames();
            int targetFrame = Math.max(1, (int) (nbFrames * 0.1));
            System.out.println("Target frame (10%): " + targetFrame);

            Frame frame = null;
            for (int i = 0; i < targetFrame; i++) {
                frame = grabber.grabImage();
                if (frame == null) break;
            }
            System.out.println("Frame obtenu: " + (frame != null ? frame.imageWidth + "x" + frame.imageHeight : "null"));

            if (frame != null) {
                // Conversion AVANT stop
                BufferedImage image;
                try (Java2DFrameConverter converter = new Java2DFrameConverter()) {
                    image = converter.convert(frame);
                }
                System.out.println("Image convertie: " + (image != null ? image.getWidth() + "x" + image.getHeight() : "null"));

                if (image != null) {
                    // Vérifier la luminosité moyenne
                    long total = 0;
                    int count = 0;
                    for (int x = 0; x < image.getWidth(); x += 5) {
                        for (int y = 0; y < image.getHeight(); y += 5) {
                            int rgb = image.getRGB(x, y);
                            int r = (rgb >> 16) & 0xFF;
                            int g = (rgb >> 8) & 0xFF;
                            int b = rgb & 0xFF;
                            total += (r + g + b);
                            count++;
                        }
                    }
                    double avg = count > 0 ? (double) total / count : 0;
                    System.out.println("Luminosité moyenne (avant stop): " + avg);

                    // Écrire la miniature
                    String out = args[1];
                    ImageIO.write(image, "JPEG", new File(out));
                    System.out.println("Miniature écrite: " + out);
                }
            }
            grabber.stop();
        }
    }
}
