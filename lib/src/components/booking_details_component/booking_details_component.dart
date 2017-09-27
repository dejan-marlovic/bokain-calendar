// Copyright (c) 2017, BuyByMarcus.ltd. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future, Stream, StreamController;
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_components/angular_components.dart';
import 'package:fo_components/fo_components.dart';
import 'package:bokain_models/bokain_models.dart';

@Component(
    selector: 'bo-booking-details',
    styleUrls: const ['booking_details_component.css'],
    templateUrl: 'booking_details_component.html',
    directives: const [CORE_DIRECTIVES, FoModalComponent, materialDirectives],
    providers: const [BillogramService],
    pipes: const [DatePipe, PhrasePipe]
)
class BookingDetailsComponent implements OnDestroy, OnChanges
{
  BookingDetailsComponent(
      this._router,
      this._phraseService,
      this._billogramService,
      this.bookingService,
      this.customerService,
      this._dayService,
      this.salonService,
      this.serviceService,
      this.serviceAddonService,
      this.userService,
      this._mailerService);

  void ngOnChanges(Map<String, SimpleChange> changes)
  {
    _addons = new List();
    _totalPrice = 0;

    if (service != null && booking != null)
    {
      _totalPrice = service.price;
      if (booking.serviceAddonIds != null) _addons = serviceAddonService.getMany(booking.serviceAddonIds).values.toList(growable: false);
      for (ServiceAddon addon in _addons)
      {
        _totalPrice += addon.price;
      }
    }
  }

  void ngOnDestroy()
  {
    _onBookingChangeController.close();
  }

  Future cancel() async
  {
    // Generate booking confirmation email
    Map<String, String> params = new Map();

    params["customer_firstname"] = customer.firstname;
    params["service_name"] = service?.name;
    params["customer_name"] = "${customer?.firstname} ${customer?.lastname}";
    params["user_name"] = "${user?.firstname} ${user?.lastname}";
    params["salon_name"] = salon.name;
    params["salon_address"] = "${salon?.street}, ${salon?.postalCode}, ${salon?.city}";
    params["date"] = _mailerService.formatDatePronounced(booking.startTime);
    params["start_time"] = _mailerService.formatHM(booking.startTime);
    params["end_time"] = _mailerService.formatHM(booking.endTime);
    params["salon_phone"] = salon.phone;
    _mailerService.mail(_phraseService.get('email_cancel_booking', params: params), _phraseService.get('booking_cancellation'), customer.email);

    await bookingService.patchRemove(booking, customerService, _dayService, salonService, userService);
    await bookingService.remove(booking.id);
    booking = null;
    confirmModalOpen = false;
    _onBookingChangeController.add(null);
  }

  Future toggleNoshow() async
  {
    booking.noshow = !booking.noshow;
    await bookingService.set(booking.id, booking);
  }

  Future generateInvoice() async
  {
    try
    {
      await _billogramService.generateNoShow(booking, customer, [service], addons);
      booking.invoiceSent = true;
      await bookingService.set(booking.id, booking);
    } on Exception catch (e)
    {
      print(e);
    }
  }

  void rebook()
  {
    bookingService.rebookBuffer = booking;
    booking = null;
    _onBookingChangeController.add(booking);
    _router.navigate(['Calendar']);
  }

  num get totalPrice => _totalPrice;

  Customer get customer => customerService.get(booking?.customerId);
  Room get room => salonService.getRoom(booking?.roomId);
  Salon get salon => salonService.get(booking?.salonId);
  Service get service => serviceService.get(booking?.serviceId);
  User get user => userService.get(booking?.userId);
  List<ServiceAddon> get addons => _addons;

  List<ServiceAddon> _addons = new List();
  num _totalPrice = 0;
  bool confirmModalOpen = false;
  final StreamController<Booking> _onBookingChangeController = new StreamController();
  final BillogramService _billogramService;
  final BookingService bookingService;
  final CustomerService customerService;
  final DayService _dayService;
  final PhraseService _phraseService;
  final SalonService salonService;
  final ServiceService serviceService;
  final ServiceAddonService serviceAddonService;
  final UserService userService;
  final MailerService _mailerService;
  final Router _router;

  @Input('booking')
  Booking booking;

  @Input('showActionButtons')
  bool showActionButtons = true;

  @Output('bookingChange')
  Stream<Booking> get onBookingChangeOutput => _onBookingChangeController.stream;
}
