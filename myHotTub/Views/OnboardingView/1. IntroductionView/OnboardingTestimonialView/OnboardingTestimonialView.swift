
import SwiftUI

struct OnboardingTestimonial {
	var id: Int
	var title: String
	var description: String
}

struct OnboardingTestimonialView: View {
	@State private var hasSeenTestimonial                    = false
	@State private var hasInit: Bool                         = false
	@State private var testimonials: [OnboardingTestimonial] = [
		OnboardingTestimonial(id: 0, title: "What I needed!", description: ""),
		OnboardingTestimonial(id: 1, title: "Outstanding!", description: "")
	]
	@State private var testimonialOffset: CGFloat            = 0
	
	var body: some View {
		GeometryReader { geometry in
			HStack(spacing: 0) {
				// Current testimonial
				if let testimonial = testimonials.first {
					testimonialContent(for: testimonial)
						.frame(width: geometry.size.width)
				}
				
				// Next testimonial
				if testimonials.count > 1 {
					testimonialContent(for: testimonials[1])
						.frame(width: geometry.size.width)
				}
			}
			.offset(x: testimonialOffset)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
			.onAppear {
				if !hasSeenTestimonial {
					hasSeenTestimonial = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
						nextTestimonial(width: geometry.size.width)
					}
				}
			}
		}
		.clipped()
		.padding(.horizontal)
		.onAppear {
			testimonials.shuffle()
		}
		
		Spacer()
	}
	
	@ViewBuilder
	private func testimonialContent(for testimonial: OnboardingTestimonial) -> some View {
		VStack {
			VStack(spacing: 30) {
				HStack(alignment: .bottom) {
					Image(systemName: "laurel.leading")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.clipped()
						.foregroundStyle(Color.white)
						.frame(width: 45, alignment: .center)
						.scaleEffect(1.2)

					VStack {
						VStack(spacing: 9) {
							Text(testimonial.title)
								.foregroundStyle(Color.white)
								.lineLimit(1)
								.font(.title2.italic())
								.layoutPriority(100)
								.truncationMode(.tail)

							HStack (spacing: 3) {
								Image(systemName: "star.fill")
									.foregroundColor(.yellow)
								Image(systemName: "star.fill")
									.foregroundColor(.yellow)
								Image(systemName: "star.fill")
									.foregroundColor(.yellow)
								Image(systemName: "star.fill")
									.foregroundColor(.yellow)
								Image(systemName: "star.fill")
									.foregroundColor(.yellow)
							}
						}
					}
					.padding()

					Image(systemName: "laurel.trailing")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.clipped()
						.foregroundStyle(Color.white)
						.frame(width: 45, alignment: .center)
						.scaleEffect(1.2)
				}

				if !testimonial.description.isEmpty {
					Text("\"\(testimonial.description)\"")
						.foregroundStyle(Color.white)
						.multilineTextAlignment(.center)
						.italic()
				}
			}
		}
		.frame(minHeight: 100)
	}
	
	func nextTestimonial(width: CGFloat) {
		guard testimonials.count > 1 else { return }
		
		withAnimation(.easeInOut(duration: 0.6)) {
			testimonialOffset = -width
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
			if let firstTestimonial = testimonials.first {
				testimonials.append(firstTestimonial)
				testimonials.remove(at: 0)
			}
			
			testimonialOffset = 0
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
				nextTestimonial(width: width)
			}
		}
	}
}
